//
//  CrashSDKUtils.m
//  YYMobileCore
//
//  Created by 涂飞 on 16/1/4.
//  Copyright © 2016年 YY.inc. All rights reserved.
//

#import "CrashSDKUtils.h"
#import "YYUtility.h"
#import "AuthSrv.h"

//#if OFFICIAL_RELEASE
#define MARKET_STRING @"official"
//#else
//#define MARKET_STRING @"dev"
//#endif


//#if OFFICIAL_RELEASE
//#define CRASH_APPID @"yymip"
//#else
#define CRASH_APPID @"yym-onepiece-ip"
//#endif

@implementation CrashSDKUtils

+ (void)enable
{
    
    [[CrashReport sharedObject] initWithAppid:CRASH_APPID market:MARKET_STRING];
    
    [[CrashReport sharedObject] setCrashCallback:^(NSString *crashId, NSString *crashDumpFile){
        //这个Block不可以捕获外面的变量，会导致上报不正常
        
        uint32_t userId = (uint32_t)[[AuthSrv sharedInstance] getUserId];
        NSString *buildVersion = [YYUtility appBuild];
        if (!buildVersion) {
            buildVersion = @"";
        }
        NSString *modelName = [YYUtility modelName];
        if (!modelName) {
            modelName = @"";
        }
        buildVersion = [@"build:" stringByAppendingString:buildVersion];
        NSMutableDictionary *extInfo = [@{@"uid": [@(userId) stringValue], @"build": buildVersion, @"model": modelName} mutableCopy];
        
        //从 LibraryVersionNumber.json 获取各个sdk的版本号
        NSDictionary *sdkInfo = [CrashSDKUtils SDKVersionInfo];
        if (sdkInfo) {
            [extInfo addEntriesFromDictionary:sdkInfo];
        }
        [YYLogger info:@"CrashSDKUtils" message:@"crashsdk cur userId = %@", @(userId)];
        [YYLogger info:@"CrashSDKUtils" message:@"crashsdk cur crashId = %@", crashId];
        [YYLogger info:@"CrashSDKUtils" message:@"crashsdk cur extInfo = %@", extInfo];
        
        [[CrashReport sharedObject] setExtInfo:extInfo];
        [[CrashReport sharedObject] setUserLogFile:[YYLogger logFilePath]];
        
    }];
    
    
    [YYLogger info:@"CrashSDKUtils" message:@"enable crash sdk utils userlog %@, crash_appid = %@, market_str = %@", [YYLogger logFilePath], CRASH_APPID, MARKET_STRING];
}
    
+ (NSDictionary *)SDKVersionInfo {
    
    return @{@"ffmpeg/ffmpeg-271-ios": @"271150819.5823.0",
             @"hdstatsdk": @"3.1.89",
             @"yylivesdk": @"6.1.1",
             @"imsdk": @"6.2.6",
             @"gpuimagesdk": @"0.2.18",
             @"crashreportsdk": @"1.5.3",
             @"hdadtsdk": @"1.1.4",
             @"libyuv": @"1194.5004.0",
             @"yycloudbs2sdk": @"1.2.9",
             @"transsdk": @"1.2.2",
             @"iospushsdk": @"1.0.36"};
}

+ (void)uninit
{
    [YYLogger info:@"CrashSDKUtils" message:@"uninit"];
    [[CrashReport sharedObject] unInit];
}

+ (NSString *)lastCrashInfo
{
    NSDictionary *crashInfo = [[CrashReport sharedObject] latestCrashInfo];
    if (crashInfo)
    {
        [YYLogger info:@"CrashSDKUtils" message:@"lastCrashInfo is %@", crashInfo];
        return [NSString stringWithFormat:@"%@", crashInfo];
    }
    else
    {
        return @"";
    }
}

+ (void)deleteLastCrashInfo
{
    [YYLogger info:@"CrashSDKUtils" message:@"deleteLastCrashInfo"];
    [[CrashReport sharedObject] deleteLatestCrashInfo];
}

@end
