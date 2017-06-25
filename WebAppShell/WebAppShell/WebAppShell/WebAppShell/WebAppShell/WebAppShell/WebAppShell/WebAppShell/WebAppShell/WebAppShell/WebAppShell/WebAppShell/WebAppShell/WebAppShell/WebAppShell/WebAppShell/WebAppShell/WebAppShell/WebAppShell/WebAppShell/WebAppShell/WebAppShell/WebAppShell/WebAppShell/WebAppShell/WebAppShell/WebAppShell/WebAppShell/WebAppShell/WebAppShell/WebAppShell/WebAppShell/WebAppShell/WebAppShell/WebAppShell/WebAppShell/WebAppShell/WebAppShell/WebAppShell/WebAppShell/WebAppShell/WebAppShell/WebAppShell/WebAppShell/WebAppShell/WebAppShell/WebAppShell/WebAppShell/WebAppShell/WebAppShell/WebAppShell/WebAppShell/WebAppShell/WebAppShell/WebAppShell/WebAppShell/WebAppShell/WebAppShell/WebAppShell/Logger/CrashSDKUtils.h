//
//  CrashSDKUtils.h
//  YYMobileCore
//
//  Created by 涂飞 on 16/1/4.
//  Copyright © 2016年 YY.inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrashSDKUtils : NSObject

+ (void)enable;
+ (void)uninit;

/**
 *  如果有崩溃，返回上一次崩溃信息
 *
 *  @return 上一次的崩溃信息
 */
+ (NSString *)lastCrashInfo;

+ (void)deleteLastCrashInfo;
    
+ (NSDictionary *)SDKVersionInfo;

@end
