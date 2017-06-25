//
//  YYLoggerInternal.m
//  YYMobileFramework
//
//  Created by xianmingchen on 16/4/19.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import "YYLoggerInternal.h"
#import "ZipUtil.h"
#import "LogDefine.h"
#import "YYUtility.h"
#import "YYLoggerFileCompress.h"
#import <sys/stat.h>
#import <UIKit/UIApplication.h>
#import "CommonFileUtils.h"
#import "YYLogger.h"

#define kTimerInterval 60 * 60   //1小时
#define kKeepTime 3600 * 24 * 7 //保留七天
#define kDateFormatter @"yyyy_MM_dd_HH"
#define kDateRegular @"\\d{4}_\\d{2}_\\d{2}_\\d{2}"
#define kLogDescriptionFileName @"LogDescription.txt"
#define kCrashFileName @"CrashFile.log"
#define kTmp @"tmp"


#define kUploadFileDateFormatter @"YYYY-MM-dd-HH-mm-ss"

NSString* const RAW_LOG_EXTENSION = @"log";
NSString* const ZIP_LOG_EXTENSION = @"zip";

static NSUInteger const MaxUploadLogFileSize     = 30 * (1<<20);    //上传日志最大文件大小(压缩前):30M



@interface YYLoggerInternal ()
@property (nonatomic, strong) dispatch_queue_t fileOperateQueue;
@property (nonatomic, copy) NSString *logFileDir;
@property (nonatomic, copy) NSString *currentLogPath;
@property (nonatomic, strong) NSFileHandle *currentFileHandle;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) NSString *logDescriptionFilePath;
@property (nonatomic, strong) NSFileHandle *logDescriptionFileHandle;
@property (nonatomic, assign) BOOL isDirectoryCreateSuc;
@end

@implementation YYLoggerInternal

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static YYLoggerInternal *instance = nil;
    
    dispatch_once(&onceToken, ^{
        instance = [[YYLoggerInternal alloc] init];
    });
    
    return instance;
}

#pragma mark - Init
- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _fileOperateQueue = dispatch_queue_create("com.yy.loggerV2_file_operate_queue", DISPATCH_QUEUE_SERIAL);

        BOOL result = [self createDirIfNeed];
        
        if (result)
        {
            [self createLogDescriptionFileIfNeed];
            [self createNewLogFileIfNeed];
            [self organizeLogFiles];
        }
        
        [self createNewTimer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createNewTimer
{
    [self destroyTimer];
    
    NSTimeInterval interval = [self timeIntervalToNextHour];
    _timer =  [NSTimer timerWithTimeInterval:interval target:self selector:@selector(timerFire:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (NSTimeInterval)timeIntervalToNextHour
{
    NSDate *date = [NSDate date];
    
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    
    NSInteger interval = [zone secondsFromGMTForDate:date];
    NSDate *localeDate = [date  dateByAddingTimeInterval:interval];
    
    NSDate *oneHourLater  = [NSDate dateWithTimeIntervalSinceNow:3600]; //一个小时一后
    NSDate *adjustDate = [self adjustDate:oneHourLater];
    
    NSTimeInterval timeInterval = [adjustDate timeIntervalSinceDate:localeDate];
    
    return timeInterval;
}

- (BOOL)createDirIfNeed
{
    BOOL result = YES;
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _logFileDir = [cachesDirectory stringByAppendingPathComponent:@"LogsV2"];
    
    NSString *dir = _logFileDir;
    NSError *error = nil;
    _isDirectoryCreateSuc = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dir
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            _isDirectoryCreateSuc = NO;
            result = NO;
            NSLog(@"Error occurred while creating loggerV2 dir(%@): %@", dir, error);
        }
    }
    
    //创建一个tmp子目录存放解压出来的log
    NSString *unZipDirectory = [_logFileDir stringByAppendingPathComponent:kTmp];
    if (![[NSFileManager defaultManager] fileExistsAtPath:unZipDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:unZipDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            result = NO;
            [YYLogger error:TLogger message:@"Error occurred while creating  unZipTmp(%@): %@", unZipDirectory, error];
            _isDirectoryCreateSuc = NO;
        }
    }
    
    return result;
}

- (void)createLogDescriptionFileIfNeed
{
    _logDescriptionFilePath = [_logFileDir stringByAppendingPathComponent:kLogDescriptionFileName];
    
    dispatch_async(_fileOperateQueue, ^{

        if (![[NSFileManager defaultManager] fileExistsAtPath:_logDescriptionFilePath]) {
            [[NSFileManager defaultManager] createFileAtPath:_logDescriptionFilePath
                                                    contents:nil
                                                  attributes:nil];
        }
        
        _logDescriptionFileHandle = [NSFileHandle fileHandleForWritingAtPath:_logDescriptionFilePath];
        [_logDescriptionFileHandle seekToEndOfFile];
    });
}

//按当前时区调整时间，只保留到小时。
- (NSDate *)adjustDate:(NSDate *)dateToAdjust
{
    //只保留到小时
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *dateToAdjustComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour) fromDate:dateToAdjust];

    calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSDate *resultDate = [calendar dateFromComponents:dateToAdjustComponents];
    return resultDate;

}

- (void)createNewLogFileIfNeed
{
    dispatch_async(_fileOperateQueue, ^{
        
        NSDate* date = [NSDate date];
        if (_currentFileHandle)
        {
            [_currentFileHandle synchronizeFile];
            [_currentFileHandle closeFile];
            _currentFileHandle = nil;
        }
        //log at most one file a day
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:kDateFormatter];
        
        _currentLogPath = [NSString stringWithFormat:@"%@/%@.log", _logFileDir, [formatter stringFromDate:date]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_currentLogPath])
        {
        
            BOOL createSucc = [[NSFileManager defaultManager] createFileAtPath:_currentLogPath
                                                    contents:nil
                                                  attributes:nil];
            if (createSucc)
            {
                logItemCount = 0;
                NSString *desc = [NSString stringWithFormat:@"%@ \r\n", _currentLogPath.lastPathComponent];
                [_logDescriptionFileHandle writeData:[desc dataUsingEncoding:NSUTF8StringEncoding]];
#if 0
                // 每个日志文件都加这几行
                extern NSString *const kAppStartTimeKey;
                NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:kAppStartTimeKey];
                NSDateFormatter *startDateFormatter = [[NSDateFormatter alloc] init];
                [startDateFormatter setDateFormat:@"yyyy_MM_dd HH:mm:ss"];
                NSString *dateString = [startDateFormatter stringFromDate:date];
                [YYLogger info:TApp message:@"APP Start at:%@", dateString];
#endif
                [YYLogger info:TApp
                       message:@"Version info : %@(%@_%@, BUILD %@), Channel: %@", [YYUtility appVersion],
                 [YYUtility svnVersion], [YYUtility buildType], [YYUtility appBuild],
                 [YYUtility getAppSource]];
//                [YYLogger info:TApp
//                       message:@"Device Info : Model:%@, SystemVersion:%@, DeviceID:%@, IDFV:%@, isJailbreak:%@",
//                 [YYUtility modelName], [YYUtility systemVersion], [YYUtility deviceID],
//                 [YYUtility identifierForVendor], @([YYUtility isBroken])];
                
            }
        }
        
        _currentFileHandle = [NSFileHandle fileHandleForWritingAtPath:_currentLogPath];
        [_currentFileHandle seekToEndOfFile];
    });
}

static unsigned long long logItemCount = 0;
static unsigned long long globalcurrentFileSize = 0;

- (void)logToFile:(NSString *)text
{
    
    if ([text length] <= 0)
    {
        return;
    }
    
    dispatch_async(_fileOperateQueue, ^{
        @try {
            //降低查询文件大小的频率
            logItemCount++;
            unsigned long long maxFileSize = 1000 * 1000 * 100;
            if (logItemCount % 5000 == 1)
            {
                struct stat statBuf;
                const char *cpath = [_currentLogPath fileSystemRepresentation];
                if (cpath && stat(cpath, &statBuf) == 0)
                {
                    
                    globalcurrentFileSize = statBuf.st_size;
                    if (globalcurrentFileSize < maxFileSize)
                    {
                        [_currentFileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                }
            }
            else
            {
                if (globalcurrentFileSize < maxFileSize) {
                    [_currentFileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
                }
            }
            
        } @catch(NSException *e) {
            NSLog(@"Error: cannot write log file with exception %@", e);
        }
    });
}

- (void)destroyTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)timerFire:(NSTimer *)timer
{
    [self organizeLogFiles];
    [self createNewLogFileIfNeed];

    [self destroyTimer];
    _timer = [NSTimer timerWithTimeInterval:kTimerInterval target:self selector:@selector(timerFire:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (NSDate *)dateFromFileName:(NSString *)fileName
{
    NSDateFormatter* ymdhmsDateFormatter = [[NSDateFormatter alloc] init];
    [ymdhmsDateFormatter setDateFormat:kDateFormatter];
    [ymdhmsDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSRange range = [fileName rangeOfString:kDateRegular options:NSRegularExpressionSearch];
    NSDate* logDate = nil;
    if (range.location != NSNotFound) {
        NSString* dateStr = [fileName substringWithRange:range];
        logDate = [ymdhmsDateFormatter dateFromString:dateStr];
    }
    return logDate;
}

- (void)organizeLogFiles
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(_fileOperateQueue, ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (_logFileDir) {
            NSArray *cachedFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_logFileDir error:nil];
            
            if (nil == cachedFiles || ([cachedFiles count] < 1)) {
                return;
            }
            
            __block NSMutableArray* zipLogFiles = [NSMutableArray arrayWithCapacity:[cachedFiles count]];
            __block NSMutableArray* rawLogFiles = [NSMutableArray arrayWithCapacity:[cachedFiles count]];
            
            NSTimeInterval expire_interval = kKeepTime;
            NSDate* expireDate = [NSDate dateWithTimeIntervalSinceNow:-expire_interval];
            [cachedFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (![obj isKindOfClass:[NSString class]]) {
                    return ;
                }
                
                NSString* fileName = obj;
                // 原始log文件或者压缩后的log文件
                if (fileName && [[fileName pathExtension] isEqualToString:RAW_LOG_EXTENSION]) {
                    NSDate* logDate = [strongSelf dateFromFileName:fileName];
                    if (logDate != nil) {
                        NSString* fullPath = [_logFileDir stringByAppendingPathComponent:fileName];
                        [rawLogFiles addObject:@[logDate, fullPath]];
                    }
                } else if (fileName && [[fileName pathExtension] isEqualToString:ZIP_LOG_EXTENSION]) {
                    NSDate* logDate = [strongSelf dateFromFileName:fileName];
                    if (logDate != nil) {
                        [zipLogFiles addObject:@[logDate, [_logFileDir stringByAppendingPathComponent:fileName]]];
                    }
                }
            }];
            
            //删除过期的压缩日志文件
            [zipLogFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (![obj isKindOfClass:[NSArray class]]) {
                    return ;
                }
                
                NSDate* logDate = [obj firstObject];
                if ([logDate compare:expireDate] == NSOrderedAscending) {
                    NSString* fullPath = [obj lastObject];
                    
                    if ([[NSFileManager defaultManager] isDeletableFileAtPath:fullPath]) {
                        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
                    }
                }
            }];
            
            //将其余日志文件压缩
            [rawLogFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                NSDate* logDate = [obj firstObject];
                NSString* fullPath = [obj lastObject];
                BOOL shouldDelete = YES;
                if ([logDate compare:expireDate] != NSOrderedAscending)
                {
                    NSString* zipFilePath = [[fullPath stringByDeletingPathExtension] stringByAppendingPathExtension:ZIP_LOG_EXTENSION];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:zipFilePath]) {
                        if ([[NSFileManager defaultManager] isDeletableFileAtPath:zipFilePath]) {
                            [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:NULL];
                        }
                    }
                    
                    // 对日志文件进行压缩
                    shouldDelete = [ZipUtil gzipCompressFile:fullPath
                                                 zipFilePath:zipFilePath
                                                  withHeader:YES];
                    
                }
                
                if (shouldDelete
                        && [[NSFileManager defaultManager] isDeletableFileAtPath:fullPath]
                        && ![fullPath isEqualToString:_currentLogPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
                }
            }];
        }
    });
}

- (NSString *)generateUploadedZipFileName
{
    NSString *resultString = nil;
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kUploadFileDateFormatter];
    
    NSString *dateString = [formatter stringFromDate:date];
    
//    long long uid = [[AuthSrv sharedInstance] getUserId];
//    
//    if (uid > 0)
//    {
//        resultString = [NSString stringWithFormat:@"iOS_%lld_%@.zip", uid, dateString];
//    }
//    else
//    {
        resultString = [NSString stringWithFormat:@"iOS_unknown_userID_%@.zip", dateString];
//    }
    
    return resultString;
}

- (BOOL)checkDirectoryCreateSucceed
{
    BOOL result = YES;
    if (!_isDirectoryCreateSuc)
    {
        result = NO;
    }
    
    return result;
}

- (void)logFileZipWithLogsFils:(NSArray *)fileNamesArray completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock
{
    __block LogErrorCode logErrorCode = LogErrorCodeOK;
    
    //检查目录是否存在
    if (![self checkDirectoryCreateSucceed])
    {
        logErrorCode = LogErrorCodeDirNotExist;
        [self finishedOperateOnMainThreadWithCompletionBlock:completionBlock logPath:nil errorCode:logErrorCode];
        return;
    }
    //是否有漰溃日志也记录到log中
    [self recordCrashDescription];
    
    //压缩整理文件
    [self organizeLogFiles];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_fileOperateQueue, ^{
        __strong typeof(weakSelf)  strongSelf = weakSelf;
        
        NSString *fileToUploadPath = [[_logFileDir stringByAppendingPathComponent:@"tmp"]   stringByAppendingPathComponent:[strongSelf generateUploadedZipFileName]];
        
        do
        {
            //检查是否名空间解压需要上传的日志
            NSMutableArray *filePathArray = [NSMutableArray array];
            for (NSString *fileName in fileNamesArray)
            {
                NSString *filePath = [_logFileDir stringByAppendingPathComponent:fileName];
                [filePathArray addObject:filePath];
            }
            
            unsigned long long fileSize = [self logToUploadedFilesSizeWithFiles:filePathArray];
            
            if ([self freeDiskSpaceInBytes] < fileSize)
            {
                logErrorCode = LogErrorCodeNotEnoughStorage;
                break;
            }
            
            
            NSMutableArray *filePathToBeCompressArray = [NSMutableArray array];
            NSArray *logFilePathsArray = nil;
            if (fileNamesArray == nil || [fileNamesArray count] == 0)
            {
                [YYLogger error:TLogger message:@"file name array is empty"];
            }
            else
            {
                logFilePathsArray = [strongSelf unZipFilesWithZipFiles:fileNamesArray];
                if (logFilePathsArray != nil && [logFilePathsArray count] == 0)
                {
                    logErrorCode = LogErrorCodeCreateDeCompressFail;
                    break;
                }
            }
            
            [filePathToBeCompressArray addObjectsFromArray:logFilePathsArray];
            
            //加上崩溃日志和描述文件
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:_logDescriptionFilePath])
            {
                [filePathToBeCompressArray addObject:_logDescriptionFilePath];
            }
            
            NSString *crashLogPath = [_logFileDir stringByAppendingPathComponent:kCrashFileName];
            if ([fileManager fileExistsAtPath:crashLogPath])
            {
                [filePathToBeCompressArray addObject:crashLogPath];
            }
            
            //压缩结果
            LogCompressResult compressResult = [YYLoggerFileCompress compressFiles:filePathToBeCompressArray toPath:fileToUploadPath deleFileAfterCompress:YES];
            if (compressResult == LogCompressResultOK)
            {
                logErrorCode = LogErrorCodeOK;
            }
            else if (compressResult == LogCompressResultCompressFail)
            {
                logErrorCode = LogErrorCodeCompressZipFileFail;
            }
            else if (compressResult == LogCompressResultParamError)
            {
                logErrorCode = LogErrorCodeCompressParamError;
            }
            else if (compressResult == LogCompressResultCreateZipFail)
            {
                logErrorCode = LogErrorCodeCreateZipFail;
            }
            
        }while (0);
        
        
        if (logErrorCode == LogErrorCodeOK)
        {
            [strongSelf finishedOperateOnMainThreadWithCompletionBlock:completionBlock logPath:fileToUploadPath errorCode:logErrorCode];
        }
        else
        {
            [strongSelf finishedOperateOnMainThreadWithCompletionBlock:completionBlock logPath:nil errorCode:logErrorCode];
        }
        
    });

}
/**
 *  获取日志列表,返回的日志已经排好序，最新排前面
 *
 *  @param date 指定的时间
 *  @param allSize 总大小
 *  @param latterPartSize 指定时间点日志往后的大小（所如果latterPartSize为0，意思是取指定时间点往前allSize大小的日志，latterPartSize为allSize,意思是取指定时间点往后allSize大小的日志）
 */

- (NSArray *)filePathArrayForDate:(NSDate *)date allSize:(unsigned long long)allSize latterPartSize:(unsigned long long)latterPartSize
{
    if (date == nil || allSize == 0)
    {
        return nil;
    }
    
    if (!_logFileDir)
    {
        return nil;
    }
    
    NSArray *cachedFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_logFileDir error:nil];
    
    if ([cachedFiles count] < 1)
    {
        return nil;
    }
    
    NSString* const ZIP_LOG_EXTENSION = @"zip";
    NSMutableArray *resultArray = [NSMutableArray array];
    __block NSMutableArray* zipLogFiles = [NSMutableArray arrayWithCapacity:[cachedFiles count]];
    for (id object in cachedFiles)
    {
        if (![object isKindOfClass:[NSString class]]) {
            continue;
        }
        
        NSString *fileName = object;
        if (![[fileName pathExtension] isEqualToString:ZIP_LOG_EXTENSION])
        {
            continue;
        }
        
        NSDate *fileDate = [self dateFromFileName:fileName];
        if (!fileDate)
        {
            continue;
        }
        
        NSString *fullPath = [_logFileDir stringByAppendingPathComponent:fileName];
        
        [zipLogFiles addObject:@[fileDate, fullPath]];
    }
    
    //先排序
    NSArray *sortFileArray = [zipLogFiles sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSDate *fileDate1 = [obj1 firstObject];
        NSDate *fileDate2 = [obj2 firstObject];
        
        return [fileDate1 compare:fileDate2];
    }];
    
//    [YYLogger info:TLogger message:@"sortFileArray:%@", sortFileArray];
    
    NSInteger index = [self indexForDate:date inArray:sortFileArray];
    if (index == NSNotFound)
    {
        return nil;
    }
    
    unsigned long long latterPart = latterPartSize;
    unsigned long long currentlogSize = 0;
    for (NSInteger i = index + 1; i < [sortFileArray count]; i++)
    {
        NSString *fullPath = [[sortFileArray objectAtIndex:i] lastObject];
        NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
        unsigned long long fileSize = [fileAttr fileSize];
        if (currentlogSize + fileSize <= latterPart)
        {
            [resultArray insertObject:[fullPath lastPathComponent] atIndex:0];
            currentlogSize += fileSize;
        }
        else
        {
            break;
        }
    }
    //再从index往前拿，此时要拿maxSize - currentlogSize大小的日志
    for (NSInteger i = index; i >= 0 && i < [sortFileArray count]; i--)
    {
        NSString *fullPath = [[sortFileArray objectAtIndex:i] lastObject];
        NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
        unsigned long long fileSize = [fileAttr fileSize];
        if (currentlogSize + fileSize <= allSize)
        {
            [resultArray addObject:[fullPath lastPathComponent]];
            currentlogSize += fileSize;
        }
        else
        {
            [resultArray addObject:[fullPath lastPathComponent]];
            currentlogSize += fileSize;
            break;
        }
    }
    
    [YYLogger info:TLogger message:@"resultArray:%@", resultArray];
    
    return resultArray;
}

- (NSInteger)indexForDate:(NSDate *)date inArray:(NSArray *)array
{
    NSInteger result = NSNotFound;
    
    NSDate *minDate = [[array firstObject] firstObject];
    NSDate *maxDate = [[array lastObject] firstObject];
    
    if ([date compare:minDate] == NSOrderedAscending)
    {
        result = 0;
    }
    else if ([date compare:maxDate] == NSOrderedDescending)
    {
        result = [array count] - 1;
    }
    else
    {
        for (NSInteger i = [array count] - 1; i >= 0; i--)
        {
            NSDate *logDate = [[array objectAtIndex:i] firstObject];
            if ([date compare:logDate] == NSOrderedSame) {
                result = i;
                break;
            }
            else
            {
                continue;
            }
        }
        
        if (result == NSNotFound) //有可能这个小时没有打日志
        {
            //继续从后往前找到第一个比这个时间小的日志的下标
            for (NSInteger i = [array count] - 1; i >= 0; i--)
            {
                NSDate *logDate = [[array objectAtIndex:i] firstObject];
                if ([date compare:logDate] == NSOrderedDescending) {
                    result = i;
                    break;
                }
                else
                {
                    continue;
                }
            }

        }
    }
    
    return result;
}

- (NSString *)logFilePathBeforDate:(NSDate *)date allSize:(unsigned long long)size
{
    NSString *filePath = [_logFileDir stringByAppendingPathComponent:@"merged.log"];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    NSDate *forDate = [self adjustDate:date];
    NSArray *zipFileNameArray = [self filePathArrayForDate:forDate allSize:size latterPartSize:0];
    NSArray *unZipFilePathArry = [self unZipFilesWithZipFiles:zipFileNameArray];
    

    NSInteger count = [unZipFilePathArry count];
    NSMutableData *mergeData = [[NSMutableData alloc] init];
    if (count > 0)
    {
        for (NSInteger i = count - 1; i >= 0; i--)
        {
            NSString *unZipFilePath = [unZipFilePathArry objectAtIndex:i];
            NSData *data = [NSData dataWithContentsOfFile:unZipFilePath];
            [mergeData appendData:data];
            [[NSFileManager defaultManager] removeItemAtPath:unZipFilePath error:nil];
        }
    }
    
    BOOL succeed = [mergeData writeToFile:filePath atomically:NO];
    if (!succeed)
    {
        filePath = nil;
    }
    
    return filePath;
}


- (void)logFileForDate:(NSDate *)date maxSize:(unsigned long long)maxSize completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock
{
    __weak typeof(self)weakSelf = self;
    [self organizeLogFiles];
    dispatch_async(_fileOperateQueue, ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        NSDate *forDate = [strongSelf adjustDate:date];
        NSArray *fileNameReveredArray = [strongSelf filePathArrayForDate:forDate allSize:maxSize latterPartSize:maxSize / 2];
        NSMutableArray *fileNameArray = [NSMutableArray array];
        
        //倒序一下
        [fileNameReveredArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj)
            {
                [fileNameArray insertObject:obj atIndex:0];
            }
        }];
        
        LogErrorCode logErrorCode = LogErrorCodeOK;
        NSArray *unCompressFilePath = [strongSelf unZipFilesWithZipFiles:fileNameArray];
        
        NSString *uploadFilePath = [[CommonFileUtils cachesDirectory]
                                    stringByAppendingPathComponent:@"logfile_upload.log"];
        
        NSDate *uploadDate = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:kUploadFileDateFormatter];
        NSString *dateString = [formatter stringFromDate:uploadDate];
        
        NSString *uploadFileZip = [[[uploadFilePath stringByDeletingPathExtension] stringByAppendingString:dateString] stringByAppendingPathExtension:@"zip"];
        
        do
        {
            
            if ([CommonFileUtils isFileExists:uploadFilePath]) {
                [CommonFileUtils deleteFileWithFullPath:uploadFilePath];
            }
            
            // 为了创建一个日志文件
            NSError *error;
            [@"\n" writeToFile:uploadFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if (error) {
                logErrorCode = LogErrorCodeFeedbackCreateFileFail;
                break;
            }
            
            NSInteger logFileCount = [unCompressFilePath count];
            if (logFileCount <= 0)
            {
                logErrorCode = LogErrorCodeDirNotExist;
                break;
            }
            
            
            NSInteger beginIndex = 0;
            
            NSUInteger allFileSize = 0;
            NSUInteger leftSize = 0;
            BOOL largerTanMax = NO;
            for (NSInteger j = logFileCount - 1; j >= 0; j--) {
                NSString *logPath = unCompressFilePath[j];
                if (logPath && [CommonFileUtils isFileExists:logPath]) {
                    NSFileManager* manager = [NSFileManager defaultManager];
                    long long fileSize = [[manager attributesOfItemAtPath:logPath error:nil] fileSize];
                    allFileSize += fileSize;
                    if (allFileSize > MaxUploadLogFileSize) {
                        allFileSize -= fileSize;
                        leftSize = MaxUploadLogFileSize - allFileSize;
                        beginIndex = j;
                        largerTanMax = YES;
                        break;
                    }
                    else
                    {
                        beginIndex = j;
                    }
                }
            }
            
            //这个刚好要超最大限制那部分要特殊处理
            if (beginIndex >= 0 && beginIndex < logFileCount && largerTanMax)
            {
                NSString *logPath = unCompressFilePath[beginIndex];
                NSString *strData = [[NSString alloc]initWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:nil];
                NSUInteger strLength = strData.length;
                if (strLength > leftSize){
                    strData = [strData substringFromIndex:(strLength - leftSize)];
                    //这里意思要拿到完的一条行日志的开头
                    NSRange range = [strData rangeOfString:@"\n"];
                    NSUInteger index = range.location + range.length;
                    if (index < strData.length){
                        strData = [strData substringFromIndex:index];
                    }
                }
                [CommonFileUtils appendContent:strData toFilePath:uploadFilePath];
            }
            
            if (largerTanMax)
            {
                beginIndex += 1;
            }

            for (NSInteger i = beginIndex; i < logFileCount; i++) {
                NSString *logPath = unCompressFilePath[i];
                if (logPath && [CommonFileUtils isFileExists:logPath]) {
                    NSString *logStr = [NSString stringWithContentsOfFile:logPath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:NULL];
                    [CommonFileUtils appendContent:logStr toFilePath:uploadFilePath];
                    [YYLogger info:TLogUpload message:@"UpLoad Log File:%@",[logPath lastPathComponent]];
                }
            }
            
            [[NSFileManager defaultManager] removeItemAtPath:uploadFileZip error:nil];
            //描述文件
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSMutableArray *filePathToBeCompressArray = [NSMutableArray array];
            [filePathToBeCompressArray addObject:uploadFilePath];
            if ([fileManager fileExistsAtPath:_logDescriptionFilePath])
            {
                [filePathToBeCompressArray addObject:_logDescriptionFilePath];
            }
            
            //压缩结果
            LogCompressResult compressResult = [YYLoggerFileCompress compressFiles:filePathToBeCompressArray toPath:uploadFileZip deleFileAfterCompress:YES];
            if (compressResult == LogCompressResultOK)
            {
                logErrorCode = LogErrorCodeOK;
            }
            else if (compressResult == LogCompressResultCompressFail)
            {
                logErrorCode = LogErrorCodeCompressZipFileFail;
            }
            else if (compressResult == LogCompressResultParamError)
            {
                logErrorCode = LogErrorCodeCompressParamError;
            }
            else if (compressResult == LogCompressResultCreateZipFail)
            {
                logErrorCode = LogErrorCodeCreateZipFail;
            }
            
        }while (0);
        
        if (logErrorCode == LogErrorCodeOK)
        {
            [strongSelf finishedOperateOnMainThreadWithCompletionBlock:completionBlock logPath:uploadFileZip errorCode:logErrorCode];
        }
        else
        {
            [strongSelf finishedOperateOnMainThreadWithCompletionBlock:completionBlock logPath:nil errorCode:logErrorCode];
        }
        
    });
}

- (void)logFileFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock
{
    NSDate *fromDateAdjust = [self adjustDate:fromDate];
    NSDate *toDateAdjust = [self adjustDate:toDate];
    NSArray *fileNameArray = [self filePathArrayFromDate:fromDateAdjust toDate:toDateAdjust];
    
    [self logFileZipWithLogsFils:fileNameArray completion:completionBlock];
}

//返回nil为传入参数为空，返回不nil但是无内容则解压出现错误
- (NSArray *)unZipFilesWithZipFiles:(NSArray *)zipFileArray
{
    if (zipFileArray == nil)
    {
        [YYLogger error:TLogger message:@"%@: zipFileArray is empty", NSStringFromSelector(_cmd)];
        return nil;
    }
    NSMutableArray *array = [NSMutableArray array];
    NSString *unZipDirectory = [_logFileDir stringByAppendingPathComponent:kTmp];
    for (NSString *fileName in zipFileArray)
    {
        @autoreleasepool {
            NSString *fullPath = [_logFileDir stringByAppendingPathComponent:fileName];
            NSString *unCompressFileLogPath = [[[unZipDirectory stringByAppendingPathComponent:fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:RAW_LOG_EXTENSION];
            
            BOOL unCompressSucc = [ZipUtil gzipUnCompressZippedFromFile:fullPath toFilePath:unCompressFileLogPath];
            
            [YYLogger info:TLogger message:@"%@ fullPath:%@, unCompressFileLogPath:%@, unCompressSucc:%@", NSStringFromSelector(_cmd), fullPath, unCompressFileLogPath, @(unCompressSucc)];
            
            if (unCompressSucc)
            {
                [array addObject:unCompressFileLogPath];
            }
            else
            {
                [array removeAllObjects];
                break;
            }
        }
    }
    
    return array;
}

- (void)finishedOperateOnMainThreadWithCompletionBlock:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock logPath:(NSString *)logPath errorCode:(NSInteger)errorCode
{
    if (completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
           completionBlock(logPath, errorCode);
        });
    }
}

- (unsigned long long)logToUploadedFilesSizeWithFiles:(NSArray *)filePathArray
{
    unsigned long long resultSize = 0;
    
    for (NSString *filePath in filePathArray)
    {
        NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        unsigned long long currentFileSize = [fileAttr fileSize];
        
        resultSize += currentFileSize;
    }
    
    return resultSize;
}

- (unsigned long long)freeDiskSpaceInBytes
{
    unsigned long long totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    }
    
    return totalFreeSpace;
}

- (void)recordCrashDescription
{
    dispatch_async(_fileOperateQueue, ^{
        
            [_currentFileHandle writeData:[@"CrashSDKUtils not CrashInfo" dataUsingEncoding:NSUTF8StringEncoding]];
 
    });
}

- (NSArray *)filePathArrayFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    if (fromDate == nil || toDate == nil)
    {
        return nil;
    }
    
    if (!_logFileDir)
    {
        return nil;
    }
    
    NSArray *cachedFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_logFileDir error:nil];
        
    if ([cachedFiles count] < 1)
    {
        return nil;
    }
    
    NSString* const ZIP_LOG_EXTENSION = @"zip";
    
    NSMutableArray *resultArray = [NSMutableArray array];
    
    for (id object in cachedFiles)
    {
        if (![object isKindOfClass:[NSString class]]) {
            continue;
        }
        
        NSString *fileName = object;
        if (![[fileName pathExtension] isEqualToString:ZIP_LOG_EXTENSION])
        {
            continue;
        }
        
        NSDate *date = [self dateFromFileName:fileName];
        if (!date)
        {
            continue;
        }
        
        NSComparisonResult fromResult = [fromDate compare:date];
        NSComparisonResult toResult = [date compare:toDate];
        
        if ((fromResult == NSOrderedAscending || fromResult == NSOrderedSame)
            && (toResult == NSOrderedAscending || toResult == NSOrderedSame))
        {
            [resultArray addObject:fileName];
        }
        
    }
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kDateFormatter];
    
    NSString *fromDateString = [formatter stringFromDate:fromDate];
    NSString *toDateString = [formatter stringFromDate:toDate];
    
    [YYLogger info:TLogger message:@"fromDate:%@  toDate:%@", fromDateString, toDateString];
    [YYLogger info:TLogger message:@"all file:%@", cachedFiles];
    [YYLogger info:TLogger message:@"filter ResultFile:%@", resultArray];
    
    return resultArray;
}



#pragma - mark Notification
- (void)didEnterBackground:(NSNotification *)notification
{
    [self destroyTimer];
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [self createNewLogFileIfNeed];
    [self organizeLogFiles];
    [self createNewTimer];
}
@end
