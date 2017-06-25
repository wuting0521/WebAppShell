//
//  UIViewController+YYViewControllers.h
//  YYMobile
//
//  Created by wuwei on 14/7/4.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YYNavigationBarAppearance;
@class YYNavigationController;

@interface UIViewController (YYViewControllers)

@property (nonatomic, weak, readonly) YYNavigationController *yy_navigationController;

- (void)yy_viewDidLoad;
- (void)yy_viewWillDisappear;
- (void)yy_viewDidAppear;
- (void)yy_dealloc;

- (UIStatusBarStyle)yy_preferredStatusBarStyle;

// 被踢时需要被dissmiss掉，默认NO，需要修改的重载
- (BOOL)needAlertDissmiss;

- (void)safePushViewController:(UIViewController *)vc animated:(BOOL)animated;

//跳转页面之前会检查是否竖屏，如果横屏则转竖屏再push
- (void)safePortraitPushViewController:(UIViewController*)viewController animated:(BOOL)animated ;

@end

#pragma mark - ViewController-Based Navigation Bar Appearance

@interface UIViewController (ViewControllerBasedNavigationBarAppearance)

/**
 *  Default is NO.
 */
- (BOOL)preferredNavigationBarHidden;

/**
 *  Default is YES.
 */
- (BOOL)preferredNavigationBarTranslucent;

/**
 *  Default is nil.
 *
 *  @param barMetrics see UIBarMetrics
 */
- (UIImage *)preferredNavigationBarBackgroundImageForBarMetrics:(UIBarMetrics)barMetrics;

/**
 *  Default is nil.
 */
- (UIImage *)preferredNavigationBarShadowImage;

/**
 *  Default is [UIColor clearColor].
 */
- (UIColor *)preferredNavigationBarBackgroundColor;

@end
