//
//  NSString+SafeSubstring.h
//  YYMobileFramework
//
//  Created by yangmengjun on 16/3/16.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SafeSubstring)

- (NSUInteger)realLength;

- (NSString *)safeSubstringToIndex:(NSRange)range;

@end
