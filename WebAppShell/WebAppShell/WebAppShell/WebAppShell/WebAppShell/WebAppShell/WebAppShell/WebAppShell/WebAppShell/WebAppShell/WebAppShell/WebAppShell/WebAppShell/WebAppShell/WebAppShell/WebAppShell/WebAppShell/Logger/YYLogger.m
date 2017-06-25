
//
//  YYLogger.m
//  Commons
//
//  Created by daixiang on 14-6-3.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "YYLogger.h"

#import "YYLoggerUtil.h"
#import "ZipUtil.h"
#import "YYLoggerInternal.h"
#import <objc/message.h>

@implementation LogConfig

- (id)init
{
    if (self = [super init])
    {
        _policy = LogFilePolicyPerLaunch;
        _outputLevel = LogLevelVerbose;
        _fileLevel = LogLevelInfo;
    }
    return self;
}

@end

@interface YYLogger ()
{
    NSString *_tag;
}

@end

@implementation YYLogger

static LogConfig *logConfig = nil;

+ (void)logFileFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock
{

    [[YYLoggerInternal shareInstance] logFileFromDate:fromDate toDate:toDate completion:completionBlock];
}

+ (void)logFileForDate:(NSDate *)date maxSize:(unsigned long long)maxSize completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock
{
    [[YYLoggerInternal shareInstance] logFileForDate:date maxSize:maxSize completion:completionBlock];
}

+ (NSString *)logFilePathBeforDate:(NSDate *)date allSize:(unsigned long long)size
{
    return [[YYLoggerInternal shareInstance] logFilePathBeforDate:date allSize:size];
}


+ (void)config:(LogConfig *)cfg
{
    if (cfg)
    {
        logConfig = cfg;
    }
    else
    {
        logConfig = [[LogConfig alloc] init];
    }
}

+ (YYLogger *)getYYLogger:(NSString *)tag
{
    static NSMutableDictionary *loggers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loggers = [[NSMutableDictionary alloc] init];
    });
    
    if (tag.length == 0) {
        tag = @"Default";
    }
    
    YYLogger *logger = nil;
    @synchronized(loggers) {
        logger = [loggers objectForKey:tag];
        if (logger == nil) {
            logger = [[YYLogger alloc] initWithTag:tag];
            [loggers setObject:logger forKey:tag];
        }
    }
    
    return logger;
}

static bool isLoggable(LogLevel level)
{
    return level >= logConfig.outputLevel;
}

static NSString *logLevelToString(LogLevel level)
{
    NSString *str;
    switch (level) {
        case LogLevelVerbose: {
            str = @"Verbose";
            break;
        }
        case LogLevelDebug: {
            str = @"Debug";
            break;
        }
        case LogLevelInfo: {
            str = @"Info";
            break;
        }
        case LogLevelWarn: {
            str = @"Warn";
            break;
        }
        case LogLevelError: {
            str = @"Error";
            break;
        }
        default: {
            str = @"Unknown";
            break;
        }
    }
    return str;
}

static NSString *logFilePath = nil;
static NSFileHandle *logFileHandle = nil;

static void clearLogFileWithoutRecent()
{
}


static void logToFile(NSString* text)
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t logQueue;
    static NSDateFormatter *dateFormatter;
    //优化减少stringFromDate的调用次数
    static NSString *dateString = nil;
    static NSDate *oldDate = nil;
    static NSString *newLineString = @"\r\n";
    dispatch_once(&onceToken, ^{
    logQueue = dispatch_queue_create("logQueue", DISPATCH_QUEUE_SERIAL);
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        dispatch_async(logQueue, ^{
            oldDate = [NSDate date];
            dateString = [dateFormatter stringFromDate:oldDate];
        });

    });
    
    dispatch_async(logQueue, ^{
        
        NSDate *currentDate = [NSDate date];
        if ([currentDate timeIntervalSinceDate:oldDate] >= 1)
        {
            dateString = [dateFormatter stringFromDate:currentDate];
            oldDate = currentDate;
        }
        
        //优化字符拼接，始化足够空间，避免内存重新分配带来的消耗
        NSMutableString *logText = [[NSMutableString alloc] initWithCapacity:[dateString length] + 1/*空格*/ + [text length] + [newLineString length]];
        
        ((void (*) (id, SEL, id))objc_msgSend)(logText, @selector(appendString:), dateString);
        ((void (*) (id, SEL, id))objc_msgSend)(logText, @selector(appendString:), @" ");
        ((void (*) (id, SEL, id))objc_msgSend)(logText, @selector(appendString:), text);
        ((void (*) (id, SEL, id))objc_msgSend)(logText, @selector(appendString:), newLineString);

        
        @try {
            [[YYLoggerUtil shareInstance] addLog:logText];
            [[YYLoggerInternal shareInstance] logToFile:logText];
            
        } @catch(NSException *e) {
            NSLog(@"Error: cannot write log file with exception %@", e);
        }
        
    });
}

static NSString *formatLogStr(NSString *tag, LogLevel level, NSString *format, va_list args)
{
    NSString *input = [[NSString alloc] initWithFormat:format arguments:args];
    NSString *thread;
    if ([[NSThread currentThread] isMainThread]) {
        thread = @"Main";
    } else {
        thread = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    }
    
    NSString *logString = [NSString stringWithFormat:@"[%@][%@][%@] %@", thread, tag, logLevelToString(level), input];
    return logString;
}

static void logInternal(NSString *tag, LogLevel level, NSString *format, va_list args)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (logConfig == nil) {
            logConfig = [[LogConfig alloc] init];
        }
    });
    
    if (isLoggable(level)) {
        NSString *logString = formatLogStr(tag, level, format, args);
        
        //NSLog性能太差，5s下每秒仅1千条，非DEBUG下不需要NSLog
#ifdef DEBUG
        NSLog(@"%@", logString);
#endif
        
        if (level >= logConfig.fileLevel && logConfig.policy != LogFilePolicyNoLogFile) {
            logToFile(logString);
        }
    }
}

+ (NSString *)logFilePath
{
    return [[YYLoggerInternal shareInstance] currentLogPath];
}

+ (NSArray *)sortedLogFileArray
{
    NSArray *sortedLogFileArray = nil;
    return sortedLogFileArray;
}

+ (NSString *)logFileDir
{
    return [YYLoggerInternal shareInstance].logFileDir;
}

+ (void)log:(NSString *)tag level:(LogLevel)level message:(NSString *)format, ...NS_FORMAT_FUNCTION(3, 4)
{
    va_list args;
    va_start(args, format);
    logInternal(tag, level, format, args);
    va_end(args);
}

+ (void)verbose:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3)
{
    va_list args;
    va_start(args, format);
    logInternal(tag, LogLevelVerbose, format, args);
    va_end(args);
}

+ (void)debug:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3)
{
    va_list args;
    va_start(args, format);
    logInternal(tag, LogLevelDebug, format, args);
    va_end(args);
}

+ (void)infoDev:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3)
{
#if !OFFICIAL_RELEASE
    va_list args;
    va_start(args, format);
    logInternal(tag, LogLevelInfoDev, format, args);
    va_end(args);
#endif
}

+ (void)info:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3)
{
    va_list args;
    va_start(args, format);
    logInternal(tag, LogLevelInfo, format, args);
    va_end(args);
}

+ (void)warn:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3)
{
    va_list args;
    va_start(args, format);
    logInternal(tag, LogLevelWarn, format, args);
    va_end(args);
}

+ (void)error:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3)
{
    va_list args;
    va_start(args, format);
    logInternal(tag, LogLevelError, format, args);
    va_end(args);
}

+ (void)cleanLogFiles {
    
    clearLogFileWithoutRecent();
}

- (void)log:(LogLevel)level message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3)
{
    va_list args;
    va_start(args, format);
    logInternal(_tag, level, format, args);
    va_end(args);
}

- (void)verbose:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2)
{
    va_list args;
    va_start(args, format);
    logInternal(_tag, LogLevelVerbose, format, args);
    va_end(args);
}

- (void)debug:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2)
{
    va_list args;
    va_start(args, format);
    logInternal(_tag, LogLevelDebug, format, args);
    va_end(args);
}

- (void)info:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2)
{
    va_list args;
    va_start(args, format);
    logInternal(_tag, LogLevelInfo, format, args);
    va_end(args);
}

- (void)warn:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2)
{
    va_list args;
    va_start(args, format);
    logInternal(_tag, LogLevelWarn, format, args);
    va_end(args);
}

- (void)error:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2)
{
    va_list args;
    va_start(args, format);
    logInternal(_tag, LogLevelError, format, args);
    va_end(args);
}

- (id)initWithTag:(NSString *)tag
{
    if (self = [super init])
    {
        _tag = tag;
    }
    return self;
}

@end
