//
//  NSArray+Safe.m
//  YYMobileFramework
//
//  Created by 方杰桦 on 15/12/14.
//  Copyright © 2015年 YY Inc. All rights reserved.
//

#import "NSMutableArray+Safe.h"

@implementation NSMutableArray (Safe)

- (void)removeObjectAtSafeIndex:(NSUInteger)index{
    
    
    if(index < self.count){
        return [self removeObjectAtIndex:index];
    }
    
    return;
}

- (void)safeAddObject:(id)object {
    if (object) {
        [self addObject:object];
    }
}

@end
