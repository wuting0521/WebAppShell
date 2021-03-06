//
//  NSDictionary+Safe.h
//  YYMobileFramework
//
//  Created by wuwei on 14-3-19.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  A safe way to access dictionary
 */
@interface NSDictionary (Safe)

- (NSString *)stringForKey:(id)key;
- (NSString *)stringForKey:(id)key or:(NSString *)fall;

- (NSNumber *)numberForKey:(id)key;
- (NSNumber *)numberForKey:(id)key or:(NSNumber *)fall;

- (NSDictionary *)dictionaryForKey:(id)key;
- (NSDictionary *)dictionaryForKey:(id)key or:(NSDictionary *)fall;

- (NSArray *)arrayForKey:(id)key;
- (NSArray *)arrayForKey:(id)key or:(NSArray *)fall;

- (NSData *)dataForKey:(id)key;
- (NSData *)dataForKey:(id)key or:(NSData *)fall;

- (id)objectForKey:(id)key expectedClass:(Class)cls;
- (id)objectForKey:(id)key expectedClass:(Class)cls or:(id)fall;

@end

@interface NSDictionary (SafeCompatible)

- (NSString *)stringForKeyCompatibleNumber:(id)key;

- (NSNumber *)numberForKeyCompatibleString:(id)key;

@end
