//
//  CommonLog.c
//  Commons
//
//  Created by daixiang on 13-2-12.
//  Copyright (c) 2013年 YY Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#if 0

#include "CommonLog.h"

static CommonLogLevel _logLevel = DEFAULT_LOG_LEVEL;
static CommonLogCategory _logCategory = DEFAULT_LOG_CATEGORY;
static NSMutableDictionary *_logCategories = nil;

//大于等于此级别的log会强制输出，不受当前设置的log级别和类别的控制
static CommonLogLevel _forceLogLevel = CommonLogLevelInfo;

static int _newCategoryOffset = 32;   //新注册的类别从32位移开始，前32位预留

static BOOL _fileLogEnabled = YES;
static CommonLogLevel _fileLogLevel = DEFAULT_FILE_LOG_LEVEL;

static NSString *_logFileDir = nil;
static NSString *_logFilePath = nil;
static NSFileHandle *_logFileHandle = nil;
static NSDateFormatter *_dateFormatter = nil;

void __setLogLevel__(CommonLogLevel level)
{
    _logLevel = level;
}

void __setForceLogLevel__(CommonLogLevel level)
{
    _forceLogLevel = level;
}

void __setFileLogEnabled__(BOOL enabled)
{
    _fileLogEnabled = enabled;
}

void __setFileLogLevel__(CommonLogLevel level)
{
    _fileLogLevel = level;
}

void __registerLogCategory__(CommonLogCategory *newCategory, NSString *newCategoryString)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logCategories = [[NSMutableDictionary alloc] initWithCapacity:10];
    });
    
    if (_newCategoryOffset < 63)
    {
        *newCategory = (unsigned long long)1 << _newCategoryOffset;
        if ([newCategoryString length] > 0)
        {
            [_logCategories setObject:newCategoryString forKey:[NSNumber numberWithUnsignedLongLong:*newCategory]];
        }
        else
        {
            LOG_ERROR(@"register new log category with empty newCategoryString");
        }
        _newCategoryOffset++;
    }
    else
    {
        *newCategory = CommonLogCategoryDefault;
        LOG_ERROR(@"max register log category reached");
    }
}

void __setLogCategory__(CommonLogCategory category)
{
    _logCategory = category;
}

void __enableLogCategory__(CommonLogCategory category)
{
    _logCategory |= category;
}

void __disableLogCategory__(CommonLogCategory category)
{
    _logCategory &= ~category;
}

NSString *__getLogFilePath__()
{
    return _logFilePath;
}

static NSString *logLevelToString(CommonLogLevel level)
{
    NSString *str;
    switch (level)
    {
        case CommonLogLevelVerbose:
            str = @"Verbose";
            break;
        case CommonLogLevelDebug:
            str = @"Debug";
            break;
        case CommonLogLevelInfo:
            str = @"Info";
            break;
        case CommonLogLevelWarning:
            str = @"Warning";
            break;
        case CommonLogLevelError:
            str = @"Error";
            break;
        case CommonLogLevelFatal:
            str = @"Fatal";
            break;
        default:
            str = @"Unknown";
            break;
    }
    return str;
}

static NSString *logCategoryToString(CommonLogCategory category)
{
    NSString *str;
    switch (category)
    {
        case CommonLogCategoryDefault:
            str = @"Default";
            break;
        case CommonLogCategoryUtils:
            str = @"Utils";
            break;
        case CommonLogCategoryHTTP:
            str = @"HTTP";
            break;
        case CommonLogCategoryLoader:
            str = @"Loader";
            break;
        case CommonLogCategoryFramework:
            str = @"Framework";
            break;
        case CommonLogCategoryUI:
            str = @"UI";
            break;
        default:
        {
            str = [_logCategories objectForKey:[NSNumber numberWithUnsignedLongLong:category]];
            if (!str)
            {
                str = @"Unknown";
            }
            break;
        }
    }
    return str;
}

static void createLogFile()
{
    static NSString *defaultLogDir = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        defaultLogDir = [cachesDirectory stringByAppendingPathComponent:@"Logs"];
    });
    
    if (!_logFileDir)
    {
        _logFileDir = defaultLogDir;
    }
    
    @synchronized (_logFileDir)
    {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:_logFileDir])
        {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:_logFileDir withIntermediateDirectories:YES attributes:nil error:&error])
            {
                NSLog(@"Error occurred while creating log dir(%@): %@", _logFileDir, error);
                _logFileDir = defaultLogDir;
                
                error = nil;
                if (![[NSFileManager defaultManager] createDirectoryAtPath:_logFileDir withIntermediateDirectories:YES attributes:nil error:&error])
                {
                    NSLog(@"Error occurred while creating log dir(%@): %@", _logFileDir, error);
                }
            }
        }
        
        if (!error)
        {
            NSDate* date = [NSDate date];
            
            //log at most one file a day
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy_MM_dd"];
            
            _logFilePath = [NSString stringWithFormat:@"%@/%@.log", _logFileDir,[formatter stringFromDate:date]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:_logFilePath])
            {
                [[NSFileManager defaultManager] createFileAtPath:_logFilePath contents:nil attributes:nil];
            
                
            }
            _logFileHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
            [_logFileHandle seekToEndOfFile];  //need to move to the end when first open
        }
    }
}

void __setLogFileDir__(NSString *dir)
{
    _logFileDir = dir;
    createLogFile();
}

static void logToFile(NSString* text)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        createLogFile();
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @synchronized (_logFileHandle) {
            if (_dateFormatter == nil)
            {
                _dateFormatter = [[NSDateFormatter alloc] init];
                [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            }
            NSString *date = [_dateFormatter stringFromDate:[NSDate date]];
            NSString *logText = [NSString stringWithFormat:@"%@ %@\r\n", date, text];
            
            @try
            {
                [_logFileHandle writeData:[logText dataUsingEncoding:NSUTF8StringEncoding]];
            }
            @catch(NSException *e)
            {
                NSLog(@"Error: cannot write log file with exception %@", e);
                _logFileHandle = nil;
                createLogFile();
            }
        }
    });
}

void __log__(CommonLogCategory category, CommonLogLevel level, NSString *format, va_list args)
{
    if (((level >= _logLevel) && (category & _logCategory)) || (level >= _forceLogLevel))
    {
        NSString *input = [[NSString alloc] initWithFormat:format arguments:args];
        NSString *thread;
        if ([[NSThread currentThread] isMainThread])
            thread = @"Main";
        else
            thread = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
        
        NSString *logString = [NSString stringWithFormat:@"[%@][%@][%@] %@", thread, logCategoryToString(category), logLevelToString(level), input];
        NSLog(@"%@", logString);

        if (_fileLogEnabled && level >= _fileLogLevel)
        {
            logToFile(logString);
        }
    }
}

//void __common_log__(CommonLogCategory category, CommonLogLevel level, const char *format, ...)
//{
//    NSString *f = [NSString stringWithFormat:@"%s", format];
//    va_list args;
//    va_start(args, format);
//    __log__(category, level, f, args);
//}

void __common_log__(CommonLogCategory category, CommonLogLevel level, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    __log__(category, level, format, args);
}

#endif
