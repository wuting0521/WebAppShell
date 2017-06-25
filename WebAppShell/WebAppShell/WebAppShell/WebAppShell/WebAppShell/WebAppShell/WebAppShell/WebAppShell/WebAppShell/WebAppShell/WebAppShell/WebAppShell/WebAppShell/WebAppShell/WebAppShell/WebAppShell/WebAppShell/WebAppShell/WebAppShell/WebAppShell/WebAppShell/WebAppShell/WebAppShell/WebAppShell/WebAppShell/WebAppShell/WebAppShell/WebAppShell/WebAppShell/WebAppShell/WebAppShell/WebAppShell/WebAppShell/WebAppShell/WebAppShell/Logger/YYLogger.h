//
//  YYLogger.h
//  Commons
//
//  Created by daixiang on 14-6-3.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger
{
    LogLevelVerbose,
    LogLevelDebug,
    LogLevelInfoDev,
    LogLevelInfo,
    LogLevelWarn,
    LogLevelError
} LogLevel;

typedef enum : NSUInteger {
    LogFilePolicyNoLogFile,
    LogFilePolicyPerDay,
    LogFilePolicyPerLaunch,
} LogFilePolicy;

@interface LogConfig : NSObject

@property (nonatomic, assign) LogFilePolicy policy;                // log文件策略
@property (nonatomic, assign) LogLevel outputLevel;                // 输出级别，大于等于此级别的log才会输出
@property (nonatomic, assign) LogLevel fileLevel;                  // 输出到文件的级别，大于等于此级别的log才会写入文件

@end

@interface YYLogger : NSObject

+ (void)config:(LogConfig *)cfg;

+ (YYLogger *)getYYLogger:(NSString *)tag;

+ (NSString *)logFilePath;

/**
 *  取日志用这接口 (通过时间段拉取)
 *
 *  @param fromDate  起始时间
 *  @param toDate   结束时间
 *  @param completionBlock 会在主线程回调, 如果没有日志文件,logFilePath 为nil.errorCode 非0则是失败,定义见LogDefine.h
 */
+ (void)logFileFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock;



/**
 *  根据给定时间获取时间点前size大小的日志，分小时的日志会合成一个文件
 *
 *  @param date 指定的时间
 *  @param size 指定的最大size 单位为Bytes
 *  @return 返回合并后文件路径，由调用者管理
 */
+ (NSString *)logFilePathBeforDate:(NSDate *)date allSize:(unsigned long long)size;

/**
 *  取日志用这接口 (拉取给定时间前后固定大小的日志)
 *
 
 *  @param date 指定的时间
 *  @param maxSize 指定的最大size 单位为Bytes
 *  @param completionBlock 会在主线程回调, 如果没有日志文件,logFilePath 为nil. errorCode 非0则是失败,定义见LogDefine.h
 */

+ (void)logFileForDate:(NSDate *)date maxSize:(unsigned long long)maxSize completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock;

+ (NSArray *)sortedLogFileArray;

+ (NSString *)logFileDir;

+ (void)log:(NSString *)tag level:(LogLevel)level message:(NSString *)format, ...NS_FORMAT_FUNCTION(3, 4);

+ (void)verbose:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);

+ (void)debug:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);

+ (void)infoDev:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);

+ (void)info:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);

+ (void)warn:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);

+ (void)error:(NSString *)tag message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);

+ (void)cleanLogFiles;

- (void)log:(LogLevel)level message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);

- (void)verbose:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2);

- (void)debug:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2);

- (void)info:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2);

- (void)warn:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2);

- (void)error:(NSString *)format, ...NS_FORMAT_FUNCTION(1, 2);

@end


//非类形式的另一个打Log函数，为方便使用
#define LogVerbose(tag, format, arg...)  [YYLogger verbose:tag message:format, ##arg]
#define LogDebug(tag, format, arg...)  [YYLogger debug:tag message:format, ##arg]
#define LogInfoDev(tag, format, arg...)  [YYLogger info:tag message:format, ##arg]
#define LogInfo(tag, format, arg...)  [YYLogger info:tag message:format, ##arg]
#define LogWarn(tag, format, arg...)  [YYLogger warn:tag message:format, ##arg]
#define LogError(tag, format, arg...)  [YYLogger error:tag message:format, ##arg]

