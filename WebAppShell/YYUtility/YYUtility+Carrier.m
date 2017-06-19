//
//  YYUtility+Carrier.m
//  YYFoundation
//
//  Created by wuwei on 14-5-30.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import "YYUtility.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "CarrierIdentifier.h"

/*
 *  The most update-to-date list of MNC&MCC is fetched
 *  from the website below: http://www.mcc-mnc.com
 */
// MCCs
static NSString * const kMobileCountryCode_China = @"460";      // 中国

// MNCs
static NSSet * kMobileNetworkCodes_ChinaMobile;     // 移动
static NSSet * kMobileNetworkCodes_ChinaUnicom;     // 联通
static NSSet * kMobileNetworkCodes_ChinaTelecom;    // 电信

static CTCarrier *carrier;

@implementation YYUtility (Carrier)

+ (void)load
{
    if (self == [YYUtility self]) {
        kMobileNetworkCodes_ChinaMobile = [NSSet setWithObjects:@"00", @"02", @"07", nil]; // 中国移动
        kMobileNetworkCodes_ChinaUnicom = [NSSet setWithObjects:@"01", @"06", nil];     // 中国联通
        kMobileNetworkCodes_ChinaTelecom = [NSSet setWithObjects:@"03", @"05", nil];    // 中国电信
    }
}

+ (NSString *)carrierName
{
    return [self carrier].carrierName ? :@"";
}

+ (NSInteger)carrierIdentifier
{
    return [self identifierOfCarrier:[self carrier]];
}

+ (CTCarrier *)carrier
{
    if (!carrier) {
        carrier = [[CTTelephonyNetworkInfo alloc] init].subscriberCellularProvider;
    }
    return carrier;
}

+ (NSInteger)identifierOfCarrier:(CTCarrier *)carrier
{
    CarrierIdentifier identifier = CarrierIdentifier_Unknown;
    do {
        if (carrier.mobileCountryCode == nil || carrier.mobileNetworkCode == nil)
        {
            identifier = CarrierIdentifier_Unknown;
            break;
        }
        
        if ([carrier.mobileCountryCode isEqualToString:kMobileCountryCode_China])
        {
            if ([kMobileNetworkCodes_ChinaMobile containsObject:carrier.mobileNetworkCode])
            {
                identifier = CarrierIdentifier_ChinaMobile;
                break;
            }
            else if ([kMobileNetworkCodes_ChinaUnicom containsObject:carrier.mobileNetworkCode])
            {
                identifier = CarrierIdentifier_ChinaUnicom;
                break;
            }
            else if ([kMobileNetworkCodes_ChinaTelecom containsObject:carrier.mobileNetworkCode])
            {
                identifier = CarrierIdentifier_ChinaTelecom;
                break;
            }
        }
        
        identifier = CarrierIdentifier_Otherwise;
        
    } while (0);
    
    return identifier;
}

@end
