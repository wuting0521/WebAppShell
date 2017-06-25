//
//  NSArray+Safe.h
//  YYMobileFramework
//
//  Created by 方杰桦 on 15/12/14.
//  Copyright © 2015年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Safe)

- (void)removeObjectAtSafeIndex:(NSUInteger)index;

- (void)safeAddObject:(id)object;

@end
