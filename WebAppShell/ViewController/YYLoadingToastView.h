//
//  YYLoadingToastView.h
//  YYMobile
//
//  Created by 武帮民 on 14-8-13.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YYLoadingToastView : UIView

+ (instancetype)instantiateLoadingToast;

+ (instancetype)instantiateLoadingToastWithText:(NSString *)msg;

@end
