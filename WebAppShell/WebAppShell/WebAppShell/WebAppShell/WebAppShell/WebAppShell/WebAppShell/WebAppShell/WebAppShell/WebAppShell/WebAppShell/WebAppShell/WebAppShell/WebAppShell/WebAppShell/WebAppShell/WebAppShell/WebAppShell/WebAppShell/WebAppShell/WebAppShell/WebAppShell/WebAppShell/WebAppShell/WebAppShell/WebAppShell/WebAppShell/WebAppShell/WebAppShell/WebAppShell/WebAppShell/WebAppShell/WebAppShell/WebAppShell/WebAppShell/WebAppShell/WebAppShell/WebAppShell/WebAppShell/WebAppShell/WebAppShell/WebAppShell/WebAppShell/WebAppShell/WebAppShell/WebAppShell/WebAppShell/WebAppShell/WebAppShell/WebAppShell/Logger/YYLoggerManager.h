//
//  YYLoggerManager.h
//  YYMobileCore
//
//  Created by penglong on 14-6-12.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YYLoggerManager : NSObject 

+ (YYLoggerManager *)sharedObject;

/**
 * 设置多少天清理一次log文件
 * @param day 多少天清理一次log文件
 */
- (void)setClearLogDay:(NSInteger)day;

@end
