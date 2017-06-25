//
//  UIColor+ColorUtil.h
//  OnePiece
//
//  Created by Wu Ting on 2017/4/14.
//  Copyright © 2017年 YY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (ColorUtil)

+ (UIColor *)colorWithHexString:(NSString *)colorString;

+ (UIColor *)colorWithHexString:(NSString *)colorString alpha:(CGFloat)alpha;

+ (UIColor *)colorWithR:(NSUInteger)r G:(NSUInteger)g B:(NSUInteger)b alpha:(CGFloat)alpha;

+ (UIColor *)colorWithRGB:(NSUInteger)rgbValue;
+ (UIColor *)colorWithARGB:(NSUInteger)argbValue;

- (CGFloat)red;
- (CGFloat)green;
- (CGFloat)blue;
@end
