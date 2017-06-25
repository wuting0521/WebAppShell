//
//  NSArray+Safe.m
//  YYMobileFramework
//
//  Created by 钟震山 on 16/8/22.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import "NSArray+Safe.h"

@implementation NSArray (Safe)

- (id)safeObjectAtIndex:(NSUInteger)index {
    if (index < self.count) {
        return [self objectAtIndex:index];
    }
    return nil;
}

- (id)safeObjectAtIndex:(NSUInteger)index expectedClass:(Class)cls
{
    if (index < self.count) {
        id ret = [self objectAtIndex:index];
        if (cls && [ret isKindOfClass:cls]) {
            return ret;
        }
    }
    return nil;
}

@end
