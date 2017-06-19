//
//  YYUtility+Device.m
//  YYMobileFramework
//
//  Created by wuwei on 14-5-30.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "YYUtility.h"
#import <sys/utsname.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <AdSupport/ASIdentifierManager.h>

#import <ifaddrs.h>
#import <net/if_dl.h>
#import <sys/socket.h>



#if !defined(IFT_ETHER)
#define IFT_ETHER 0x6
#endif

#define kIOSCellular    @"pdp_ip0"
#define kIOSWifi        @"en0"
#define kIPAddrV4       @"ipv4"
#define kIPAddrV6       @"ipv6"

@implementation YYUtility (Device)

+ (BOOL)isBroken
{
#if !TARGET_IPHONE_SIMULATOR
    
    //Apps and System check list
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"Cyd", @"ia.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"bla", @"ckra1n.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"Fake", @"Carrier.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"Ic", @"y.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"Inte", @"lliScreen.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"MxT", @"ube.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"Roc", @"kApp.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"SBSet", @"ttings.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"Wint", @"erBoard.a", @"pp"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"pr", @"iva",@"te/v", @"ar/l", @"ib/a", @"pt/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"pr", @"iva",@"te/v", @"ar/l", @"ib/c", @"ydia/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"pr", @"iva",@"te/v", @"ar/mobile", @"Library/SBSettings", @"Themes/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"pr", @"iva",@"te/v", @"ar/t", @"mp/cyd", @"ia.log"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@", @"pr", @"iva",@"te/v", @"ar/s", @"tash/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"us", @"r/l",@"ibe", @"xe", @"c/cy", @"dia/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@", @"us", @"r/b",@"in", @"s", @"shd"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@", @"us", @"r/sb",@"in", @"s", @"shd"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"us", @"r/l",@"ibe", @"xe", @"c/cy", @"dia/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"us", @"r/l",@"ibe", @"xe", @"c/sftp-", @"server"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@",@"/Syste",@"tem/Lib",@"rary/Lau",@"nchDae",@"mons/com.ike",@"y.bbot.plist"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@%@",@"/Sy",@"stem/Lib",@"rary/Laun",@"chDae",@"mons/com.saur",@"ik.Cy",@"@dia.Star",@"tup.plist"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@", @"/Libr",@"ary/Mo",@"bileSubstra",@"te/MobileSubs",@"trate.dylib"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@", @"/va",@"r/c",@"ach",@"e/a",@"pt/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@", @"/va",@"r/l",@"ib",@"/apt/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@", @"/va",@"r/l",@"ib/c",@"ydia/"] isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@", @"/va",@"r/l",@"og/s",@"yslog"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@", @"/bi",@"n/b",@"ash"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@", @"/b",@"in/",@"sh"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@", @"/et",@"c/a",@"pt/"]isDirectory:&isDirectory]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@", @"/etc/s",@"sh/s",@"shd_config"]]
        || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@", @"/us",@"r/li",@"bexe",@"c/ssh-k",@"eysign"]])
    
    {
        return YES;
    }
    else
    {
        return NO;
    }
    
    
#endif
    return NO;
}


+ (NSString *)modelName
{
    static NSString *modelName = nil;
    if (!modelName) {
        struct utsname systemInfo;
        uname(&systemInfo);
        modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    }
    return modelName;
}

+ (NSString *)systemVersion
{
    // 调用非常频繁，主要在cleanSpecialText中
    static NSString* _systemVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _systemVersion = [UIDevice currentDevice].systemVersion;
    });
    
    if (_systemVersion) {
        return _systemVersion;
    }
    
    return [UIDevice currentDevice].systemVersion;
}

+ (NSString *)userAgent {
    //[UIDevice currentDevice].systemName : 在iOS10，返回iOS；iOS10之前，返回iPhone OS. 为兼容，现写死为iPhone OS.
    return [@"iPhone OS-" stringByAppendingString:[UIDevice currentDevice].systemVersion];
}

+ (NSString *)identifierForVendor
{
    static NSString *idfv = nil;
    if (!idfv) {
        idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return idfv;
}


+ (void)checkCameraAvailable:(void (^)(void))available denied:(void(^)(void))denied restriction:(void(^)(void))restriction
{
    available = available ? : ^{};
    denied = denied ? : ^{};
    restriction = restriction ? : ^{};
    
    if  ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        // iOS7下，需要检查iPhone的隐私和访问限制项
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        switch (authStatus) {
            case AVAuthorizationStatusAuthorized:
            {
                available();
                break;
            }
            case AVAuthorizationStatusDenied:
            {
                // [设置->隐私->相机]中禁止了YY访问相机
                denied();
                break;
            }
            case AVAuthorizationStatusRestricted:
            {
                // NOTE: 这个跟[设置-通用-访问限制]似乎没有关系
                restriction();
                break;
            }
            case AVAuthorizationStatusNotDetermined:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (granted)
                        {
                            available();
                        }
                        else
                        {
                            denied();
                        }
                    });
                }];
            }
                
            default:
                break;
        }
    }
    else
    {
        restriction();
    }
}

+ (NSString *)ipAddress
{
    return [self ipAddress:YES];
}

+ (NSString *)ipAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
        @[ kIOSWifi @"/" kIPAddrV4, kIOSWifi @"/" kIPAddrV6, kIOSCellular @"/" kIPAddrV4, kIOSCellular @"/" kIPAddrV6 ] :
        @[ kIOSWifi @"/" kIPAddrV6, kIOSWifi @"/" kIPAddrV4, kIOSCellular @"/" kIPAddrV6, kIOSCellular @"/" kIPAddrV4 ] ;
    
    NSDictionary *addresses = [self getIpAddresses];
    
    __block NSString *addr;
    [searchArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        addr = addresses[obj];
        if (addr) {
            *stop = YES;
        }
    }];
    return addr ? : @"0.0.0.0";
}

+ (NSDictionary *)getIpAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionary];
    
    // retrieve the current interfaces - return 0 on success
    struct ifaddrs *interfaces;
    if (!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for (interface = interfaces; interface; interface = interface->ifa_next) {
            if (!(interface -> ifa_flags & IFF_UP)) {
                continue;
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in *)interface->ifa_addr;
            char addrBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) + 2];
            if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
                NSString *ifaName = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *ifaType;
                if (addr->sin_family == AF_INET) {
                    if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        ifaType = kIPAddrV4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *)interface->ifa_addr;
                    if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        ifaType = kIPAddrV6;
                    }
                }
                if (ifaType) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", ifaName, ifaType];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
    }
    // free memory
    freeifaddrs(interfaces);
    return addresses;
}

+ (NSString *)macAddresss
{
    static NSMutableString *macAddress = nil;
    
    if ([macAddress length] > 0) {
        return macAddress;
    }
    
    do
    {
        struct ifaddrs* addrs;
        if ( getifaddrs( &addrs ) )
            break;
        
        const struct ifaddrs *cursor = addrs;
        while ( cursor )
        {
            if ( ( cursor->ifa_addr->sa_family == AF_LINK )
                && strcmp( "en0",  cursor->ifa_name ) == 0
                && ( ( ( const struct sockaddr_dl * )cursor->ifa_addr)->sdl_type == IFT_ETHER ) )
            {
                const struct sockaddr_dl *dlAddr = ( const struct sockaddr_dl * )cursor->ifa_addr;
                const uint8_t *base = ( const uint8_t * )&dlAddr->sdl_data[dlAddr->sdl_nlen];
                
                macAddress = [[NSMutableString alloc] initWithCapacity:64];
                
                for ( int i = 0; i < dlAddr->sdl_alen; i++ )
                {
                    if (i > 0) {
                        [macAddress appendFormat:@":%02X", base[i]];
                    }
                    else
                    {
                        [macAddress appendFormat:@"%02X", base[i]];
                    }
                }
                
                break;
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    } while (NO);
    
    if (macAddress == nil) {
        macAddress = [NSMutableString stringWithString:@""];
    }
    
    return macAddress;
}

+ (NSString *)idfa
{
    static NSString *idfa = nil;
    if (!idfa) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
            idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        } else {
            idfa = @"";
        }
    }
    return idfa;
}

// 当前电量
+ (float)currentBtteryLevel {
    
    return [[UIDevice currentDevice] batteryLevel];
}

// 设备是否正在充电
+ (BOOL)isDeviceCharging {
    
    return [[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging;
}

@end
