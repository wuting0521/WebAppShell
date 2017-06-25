//
//  WABaseAPIReflectionImpl.m
//  YY2
//
//  Created by wuwei on 14-5-20.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import "WABaseAPIReflectionImpl.h"

@implementation WABaseAPIReflectionImpl

- (NSString *)module
{
    return @"";
}

- (id)invokeClientMethod:(NSString *)name parameter:(id)parameter callback:(YYWACallback)callback
{
    [YYLogger debug:TWebApp message:@"[+] WABaseAPIReflectionImpl invokeClientMethod(%@, %@, %@, %@)", self.module, name, parameter, callback];
    NSString *selectorName = [NSString stringWithFormat:@"%@:callback:", name];
    SEL selector = NSSelectorFromString(selectorName);
    if (![self respondsToSelector:selector])
    {
        return nil;
    }
    
    // Call the selector
    id result = nil;
    IMP imp = [self methodForSelector:selector];
    if (imp) {
        id(*func)(id, SEL, id, YYWACallback) = (void *)imp;
        result = func(self, selector, parameter, callback);
    }
    
    [YYLogger debug:TWebApp message:@"[-] WABaseAPIReflectionImpl invokeClientMethod(%@, %@, %@, %@)", self.module, name, parameter, callback];
    return result;
}

@end
