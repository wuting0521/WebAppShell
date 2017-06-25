//
//  NSArray+Safe.h
//  YYMobileFramework
//
//  Created by 钟震山 on 16/8/22.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Safe)

- (id)safeObjectAtIndex:(NSUInteger)index;
- (id)safeObjectAtIndex:(NSUInteger)index expectedClass:(Class)cls;

@end
