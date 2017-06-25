//
//  NSString+SafeSubstring.m
//  YYMobileFramework
//
//  Created by yangmengjun on 16/3/16.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import "NSString+SafeSubstring.h"

@implementation NSString (SafeSubstring)

- (NSUInteger)realLength
{
    return [self lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
}

- (NSString *)safeSubstringToIndex:(NSRange)range
{
    
    NSRange realRange = [self rangeOfComposedCharacterSequencesForRange:range];
    
    return [self substringWithRange:realRange];
}

@end
