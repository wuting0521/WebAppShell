//
//  YYLoggerManager.m
//  YYMobileCore
//
//  Created by penglong on 14-6-12.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import "YYLoggerManager.h"
#import "YYLogger.h"

#define KEY_TIME_CHECKER @"keyTimeCheckerLog"

@interface YYLoggerManager()

@end

@implementation YYLoggerManager
{
    NSUInteger _clearTime;
}

+ (YYLoggerManager *) sharedObject
{
    static YYLoggerManager *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

- (id) init
{
    self = [super init];
//    if(self != nil){
    
//    }
    return self;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [YYLoggerManager sharedObject];
}

- (void)setClearLogDay:(NSInteger)day
{
    _clearTime = day * 3600 * 24;
    if([self prepRecordGap] > _clearTime){
        [self removeAllFileFromDirectory:[YYLogger logFileDir]];
    }
}

- (void)removeAllFileFromDirectory:(NSString *)directory
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *docPaths = [fileManager contentsOfDirectoryAtPath:directory error:nil];
        for (NSString *filePath in docPaths) {
            NSString *itemPath = [directory stringByAppendingPathComponent:filePath];
            if([fileManager removeItemAtPath:itemPath error:nil] != YES)
            {
                NSLog(@"removeFileError: %@",filePath);
            }
        }
    });
}

- (void)record
{
    //记录时间
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger currentTime = [[NSDate date] timeIntervalSince1970];
        [[NSUserDefaults standardUserDefaults] setInteger:currentTime forKey:KEY_TIME_CHECKER];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

- (NSUInteger)prepRecordGap
{
    NSUInteger prepTime = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_TIME_CHECKER];
    if(!prepTime){
        //如果还未记录,则记录当前时间
        [self record];
        return 0;
    }
    NSInteger currentTime = [[NSDate date] timeIntervalSince1970];
    return currentTime - prepTime;
}

@end
