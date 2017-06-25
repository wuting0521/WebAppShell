//
//  YYLoggerInternal.h
//  YYMobileFramework
//
//  Created by xianmingchen on 16/4/19.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YYLoggerInternal : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, copy, readonly) NSString *logFileDir;
@property (nonatomic, copy, readonly) NSString *currentLogPath;

- (void)logToFile:(NSString *)text;

/**
 *  (通过时间段拉取)
 *
 *  @param fromDate  起始时间
 *  @param toDate   结束时间
 *  @param completionBlock 会在主线程回调, 如果没有日志文件,logFilePath 为nil, errorCode 非0则是失败
 */
- (void)logFileFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock;

/**
 *  (拉取给定时间前后固定大小的日志)
 *
 *  @param date 指定的时间
 *  @param maxSize 指定的最大size 单位为Bytes
 *  @param completionBlock 会在主线程回调, 如果没有日志文件,logFilePath 为nil, errorCode 非0则是失败
 */

- (void)logFileForDate:(NSDate *)date maxSize:(unsigned long long)maxSize completion:(void (^)(NSString *logFilePath, NSInteger errorCode))completionBlock;


/**
 *  根据给定时间获取时间点前size大小的日志，分小时的日志会合成一个文件
 *
 *  @param date 指定的时间
 *  @param size 指定的最大size 单位为Bytes
 *  @return 返回合并后文件路径，由调用者管理
 */
- (NSString *)logFilePathBeforDate:(NSDate *)date allSize:(unsigned long long)size;
@end
