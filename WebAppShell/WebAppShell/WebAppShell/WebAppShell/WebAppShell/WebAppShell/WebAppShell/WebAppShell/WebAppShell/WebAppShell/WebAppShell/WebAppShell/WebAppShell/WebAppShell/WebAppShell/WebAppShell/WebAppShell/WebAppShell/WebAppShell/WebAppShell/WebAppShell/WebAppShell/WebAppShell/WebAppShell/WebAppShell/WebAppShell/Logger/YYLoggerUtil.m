//
//  PLLogUtil.m
//  MyTest
//
//  Created by penglong on 14-6-10.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import "YYLoggerUtil.h"

@interface YYLoggerUtil ()

@property (nonatomic, strong) NSMutableString *logContent;
@property (nonatomic, strong) NSMutableString *logContent_2;

@property (nonatomic, strong) NSMutableArray *logContentArray;

@property (nonatomic, strong) NSString *splitContent;
@property (nonatomic, assign) NSInteger keepCount;
@property (nonatomic, assign) NSInteger maxCount;
@property (nonatomic, assign) NSInteger contentCount;

@property (nonatomic, copy) dispatch_queue_t queue;

@end



@implementation YYLoggerUtil

+ (YYLoggerUtil *) shareInstance
{
    static YYLoggerUtil *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

- (id) init
{
    self = [super init];
    if(self != nil){
        _keepCount = 3000;
        _maxCount = 6000;
        _logContent = [[NSMutableString alloc] initWithString:@""];
        _logContent_2 = [[NSMutableString alloc] initWithString:@""];
        _logContentArray = [NSMutableArray array];
        
        _contentCount = 0;
        _queue = dispatch_queue_create("com.yy.logger_util_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [YYLoggerUtil shareInstance];
}

- (void)setInitSplitSymbol:(NSString *)splitSymbol KeepCount:(NSInteger)keepCount maxCount:(NSInteger)maxCount
{
    _splitContent = splitSymbol;
    _keepCount = keepCount;
    _maxCount  = maxCount;
    
}


- (void) addLog:(NSString *)content
{
    __weak typeof(self)weakSelf = self;
    dispatch_barrier_async(_queue, ^{
        
        if (weakSelf.logContentArray.count < weakSelf.maxCount) {
            [weakSelf.logContentArray addObject:content];
        } else {
            if (weakSelf.keepCount < weakSelf.maxCount) {
                [weakSelf.logContentArray removeObjectsInRange:NSMakeRange(0, weakSelf.keepCount)];
            } else {
                [weakSelf.logContentArray removeObjectsInRange:NSMakeRange(0, weakSelf.maxCount / 2)];
            }
            [weakSelf.logContentArray addObject:content];
        }
        
    });

    /*
    if (weakSelf.contentCount < (weakSelf.maxCount - weakSelf.keepCount)) { //如果未超过指定数量
        
        [weakSelf.logContent appendString:content];
        if(weakSelf.splitContent){
            [weakSelf.logContent appendString:weakSelf.splitContent];
        }
        
    } else if (weakSelf.contentCount < weakSelf.maxCount){ // 未超过最大数量
        
        [weakSelf.logContent_2 appendString:content];
        if(weakSelf.splitContent){
            [weakSelf.logContent_2 appendString:weakSelf.splitContent];
        }
        
    } else {  //超过最大数量,则删除前面的部分
        
        [weakSelf.logContent_2 appendString:content];
        if(weakSelf.splitContent){
            [weakSelf.logContent_2 appendString:weakSelf.splitContent];
        }
        
        [weakSelf.logContent setString:weakSelf.logContent_2];
        [weakSelf.logContent_2 setString:@""];
        weakSelf.contentCount = weakSelf.keepCount - 1;
        
    }
    weakSelf.contentCount++;
    */
    
}

//获取log
- (NSString *)getLog
{
    NSMutableString *resultLog = [[NSMutableString alloc] initWithString:@""];
    //[resultLog appendString:[_logContent copy]];
    //[resultLog appendString:[_logContent_2 copy]];
    NSArray *logArray = [self.logContentArray copy];
    for (NSString *string in logArray) {
        [resultLog appendString:string];
        if (self.splitContent) {
            [resultLog appendString:self.splitContent];
        }
    }
    
    return resultLog;
}


@end
