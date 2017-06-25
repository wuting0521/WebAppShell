//
//  UIColor+ColorUtil.m
//  OnePiece
//
//  Created by Wu Ting on 2017/4/14.
//  Copyright © 2017年 YY. All rights reserved.
//

#import "UIColor+ColorUtil.h"

@implementation UIColor (ColorUtil)

+ (UIColor *)colorWithHexString:(NSString *)colorString {
    return [UIColor colorWithHexString:colorString alpha:1];
}

+ (UIColor *)colorWithHexString:(NSString *)colorString alpha:(CGFloat)alpha
{
    const char *cStr = [colorString cStringUsingEncoding:NSASCIIStringEncoding];
    long x = strtol(cStr + 1, NULL, 16);
    
    UIColor *color =  [UIColor colorWithRed:(float)((x >> 16) & 0x000000FF) / 255.0f green:(float)((x >> 8) & 0x000000FF) / 255.0f blue:(float)(x & 0x000000FF) / 255.0f alpha:alpha];
    
    return color;
}

+ (UIColor *)colorWithR:(NSUInteger)r G:(NSUInteger)g B:(NSUInteger)b alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:alpha];
}

+ (UIColor *)colorWithRGB:(NSUInteger)rgbValue {
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0];
}

+ (UIColor *)colorWithARGB:(NSUInteger)argbValue {
    return [UIColor colorWithRed:((float)((argbValue & 0xFF0000) >> 16))/255.0 green:((float)((argbValue & 0xFF00) >> 8))/255.0 blue:((float)(argbValue & 0xFF))/255.0 alpha:((float)((argbValue & 0xFF000000) >> 24))/255.0];
}

- (CGFloat)red {
    const CGFloat * component = CGColorGetComponents(self.CGColor);
    if (component) {
        return component[0];
    }
    
    return 0;
}

- (CGFloat)green {
    const CGFloat * component = CGColorGetComponents(self.CGColor);
    if (component) {
        return component[1];
    }
    
    return 0;
}

- (CGFloat)blue {
    const CGFloat * component = CGColorGetComponents(self.CGColor);
    if (component) {
        return component[2];
    }
    
    return 0;
}

@end
