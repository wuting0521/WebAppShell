//
//  NSMutableDictionary+Safe.h
//  YYMobileFramework
//
//  Created by penglong on 15/8/7.
//  Copyright (c) 2015年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Safe)

- (void)safeSetObject:(id)anObject forKey:(id <NSCopying>)aKey;

@end

