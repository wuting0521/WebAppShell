//
//  YYViewControllerCenter.m
//  YYMobile
//
//  Created by zhenby on 7/9/14.
//  Copyright (c) 2014 YY.inc. All rights reserved.
//

#import "YYViewControllerCenter.h"

@implementation YYViewControllerCenter

+ (UIViewController *) currentRootViewControllerInStack
{
    __block UIViewController *result = nil;
    // Try to find the root view controller programmically
    // Find the top window (that is not an alert view or other window)
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    if (topWindow.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(topWindow in windows)
        {
            if (topWindow.windowLevel == UIWindowLevelNormal)
                break;
        }
    }
    
    NSArray *windowSubviews = [topWindow subviews];
    
    [windowSubviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:
     ^(id obj, NSUInteger idx, BOOL *stop) {
         UIView *rootView = obj;
         
         if ([NSStringFromClass([rootView class]) isEqualToString:@"UITransitionView"]) {
             
             NSArray *aSubViews = rootView.subviews;
             
             [aSubViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                 UIView *tempView = obj;
                 
                 id nextResponder = [tempView nextResponder];
                 
                 if ([nextResponder isKindOfClass:[UIViewController class]]) {
                     UIViewController *viewController = nextResponder;
                     if (!viewController.isBeingDismissed) {
                         result = nextResponder;
                         *stop = YES;
                     }
                 }
             }];
             *stop = YES;
         } else {
             
             id nextResponder = [rootView nextResponder];
             
             if ([nextResponder isKindOfClass:[UIViewController class]]) {
                 UIViewController *viewController = nextResponder;
                 if (!viewController.isBeingDismissed) {
                     result = nextResponder;
                     *stop = YES;
                 }
             }
         }
     }];
    
    if (result == nil && [topWindow respondsToSelector:@selector(rootViewController)] && topWindow.rootViewController != nil) {
        result = topWindow.rootViewController;
    }
    
    return result;
}

@end
