//
//  NSMutableDictionary+Safe.m
//  YYMobileFramework
//
//  Created by penglong on 15/8/7.
//  Copyright (c) 2015年 YY Inc. All rights reserved.
//

#import "NSMutableDictionary+Safe.h"

@implementation NSMutableDictionary (Safe)

- (void)safeSetObject:(id)anObject forKey:(id <NSCopying>)aKey
{
    if (anObject == nil || aKey == nil)
    {
        return;
    }
    
    [self setObject:anObject forKey:aKey];
}
@end
