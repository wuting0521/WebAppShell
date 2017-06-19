//
//  YYUtility.h
//  YYMobileFramework
//
//  Created by wuwei on 14/6/11.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CTCarrier;

@interface YYUtility : NSObject

@end

/*==============================*/
/*      App Utilities           */
/*==============================*/
@interface YYUtility (App)

/**
 *  从YYMobile-Info.plist中读取字段
 *
 *  @param key 键
 *
 *  @return 值
 */
+ (id)valueInPlistForKey:(NSString *)key;

/**
 *  获取App版本号, 从plist从读取CFBundleShortVersion
 */
+ (NSString *)appVersion;

/**
 *  获取AppBuild号, 从plist中读取CFBundleVersion
 */
+ (NSString *)appBuild;

/**
 *  当前构建出的版本在svn中的版本号
 */
+ (NSString *)svnVersion;

/**
 *  获取bundle id
 *
 *  @return bundle id
 */
+ (NSString *)appBundleId;

/**
 *  获取YYMobileFrameworkRes.bundle的URL
 */
+ (NSURL *)URLForMobileFrameworkResourceBundle;

/**
 *  获取YYMobileFrameworkRes.bundle的路径
 */
+ (NSString *)pathForMobileFrameworkResourceBundle;

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)fileURL;

/**
 *  获取当前的构建类型(DEBUG/RELEASE)
 *
 *  @return 构建类型
 */
+ (NSString *)buildType;

/**
 * 获取平台渠道
 */
+ (NSString *)getAppSource;

/**
 * 是否来自appstore
 */
+ (BOOL)isFromAppStore;

@end

/*==============================*/
/*      Carrier Utilities       */
/*==============================*/
@interface YYUtility (Carrier)

/**
 *  获取运营商
 */
+ (CTCarrier *)carrier;

/**
 *  获取运营商类型
 */
+ (NSInteger)carrierIdentifier;

/**
 *  获取运营商名称
 */
+ (NSString *)carrierName;

/**
 *  从CTCarrier对象获取网络类型
 *  @param  carrier - CTCarrier对象
 *  @return CarrierType
 */
+ (NSInteger)identifierOfCarrier:(CTCarrier *)carrier;

@end

/*==============================*/
/*      Device Utilities        */
/*==============================*/
@interface YYUtility (Device)

+ (BOOL)isBroken;

/**
 *  获取modelName, 如iPhone5,2
 */
+ (NSString *)modelName;

/**
 *  获取系统版本
 */
+ (NSString *)systemVersion;

/**
 *  获取系统名字及版本，如iPhone OS-10.1。充值及相关协议用到。
 */
+ (NSString *)userAgent;

/**
 *  获取当前设备的 IDFV，IDFV 在某些情况下会变，不建议将其作为设备标识
 */
+ (NSString *)identifierForVendor NS_AVAILABLE_IOS(6_0);

/**
 *  获取当前的设备标识，会使用海度 SDK 中的 OpenUDID
 *
 *  @return 海度 SDK 缓存的 OpenUDID
 */
+ (NSString *)deviceID;


/**
 统计唯一标识，使用的是海度提供的 HDID，返回能确保非 nil
 */
+ (NSString *)HDID;

// 当前电量
+ (float)currentBtteryLevel;

// 设备是否正在充电
+ (BOOL)isDeviceCharging;

/**
 *  获取当前IP地址
 */
+ (NSString *)ipAddress;

/**
 *  获取当前IP地址
 *
 *  @param preferIPv4 优先取IPv4的地址 
 */
+ (NSString *)ipAddress:(BOOL)preferIPv4;

/**
 *  检查Camera是否可用, 可用则调用available; 若隐私设置中禁用了本app对相机
 *  的访问, 则调用denied; 否则视为被限制, 调用restriction
 *
 *  @param available   可用
 *  @param denied      不可用
 *  @param restriction 受限制
 */
+ (void)checkCameraAvailable:(void (^)(void))available denied:(void(^)(void))denied restriction:(void(^)(void))restriction;

+ (NSString *)macAddresss;
+ (NSString *)idfa;

@end
