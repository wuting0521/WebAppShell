//
//  CarrierIdentifier.h
//  YYMobileFramework
//
//  Created by wuwei on 14-5-30.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// 运营商类型
typedef NS_ENUM(NSUInteger, CarrierIdentifier)
{
    CarrierIdentifier_Unknown = 0,            // 未知, 网络不可用(未插SIM卡/无信号/飞行模式)
    
    CarrierIdentifier_ChinaMobile = 1,        // 中国移动
    CarrierIdentifier_ChinaUnicom = 2,        // 中国联通
    CarrierIdentifier_ChinaTelecom = 3,       // 中国电信
    
    CarrierIdentifier_Otherwise = 0x0000FFFF, // 其他运营商
};