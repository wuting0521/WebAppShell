//
//  UIViewController+YYViewControllers.m
//  YYMobile
//
//  Created by wuwei on 14/7/4.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import "UIViewController+YYViewControllers.h"

#import "FBKVOController.h"

#import <objc/runtime.h>

@interface UIViewController (YYViewControllersPrivate)

@property (nonatomic, strong) FBKVOController *navigationKVOController;

@end

@implementation UIViewController (YYViewControllers)

- (void)safePushViewController:(UIViewController *)vc animated:(BOOL)animated {
    
    if (!vc) {
        return;
    }
    
    if ([self isKindOfClass:[UINavigationController class]]) {
        
        [(UINavigationController *)self pushViewController:vc animated:animated];
        
        return;
    }
    
    if ([self isKindOfClass:[UITabBarController class]]) {
        [((UITabBarController *)self).selectedViewController safePushViewController:vc animated:animated];
        return;
    }
    
    BOOL shouldPush = NO;
    __weak UIViewController *tempController = self;
    do {
        if (tempController == tempController.navigationController.topViewController) {
            shouldPush = YES;
            
            break;
        } else {
            tempController = tempController.parentViewController;
        }
        
    }while (tempController.parentViewController);
    
    if (shouldPush) {
        [self.navigationController pushViewController:vc animated:animated];
    }
}

- (void)safePortraitPushViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        [self _turnToPortraitOrientation:UIInterfaceOrientationPortrait];
    }

    [self safePushViewController:viewController animated:animated];
}

- (void)_turnToPortraitOrientation:(UIInterfaceOrientation)orientation {
    SEL selector = NSSelectorFromString(@"setRotateLock:");
    if ([self respondsToSelector:selector]) {
        [self setValue:@(NO) forKey:@"rotateLock"];
    }
    //[UIViewController yy_AttemptRotationToInterfaceOrientation:orientation];
    
}

- (void)yy_viewWillDisappear {
    
}

- (void)yy_viewDidAppear {
    
    self.navigationController.navigationBarHidden = [self preferredNavigationBarHidden];
}

- (void)yy_viewDidLoad
{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)yy_dealloc
{
    
}

- (UIStatusBarStyle)yy_preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)needAlertDissmiss {
    return NO;
}

- (void)yy_updateRightBarButtonItems
{
    
}

- (YYNavigationController *)yy_navigationController
{
    return [self.navigationController isKindOfClass:NSClassFromString(@"YYNavigationController")] ? (YYNavigationController *)self.navigationController : nil;
}


@end

@implementation UIViewController (YYViewControllersPrivate)

@dynamic navigationKVOController;

static const char kNavigationKVOControllerKey;

- (void)setNavigationKVOController:(FBKVOController *)navigationKVOController
{
    objc_setAssociatedObject(self, &kNavigationKVOControllerKey, navigationKVOController, OBJC_ASSOCIATION_RETAIN);
}

- (FBKVOController *)navigationKVOController
{
    return objc_getAssociatedObject(self, &kNavigationKVOControllerKey);
}

@end

@implementation UIViewController (ViewControllerBasedNavigationBarAppearance)

- (BOOL)preferredNavigationBarHidden
{
    return NO;
}

- (BOOL)preferredNavigationBarTranslucent
{
    return NO;
}

- (UIImage *)preferredNavigationBarBackgroundImageForBarMetrics:(UIBarMetrics)barMetrics
{
    return nil;
}

- (UIColor *)preferredNavigationBarBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIImage *)preferredNavigationBarShadowImage
{
    return nil;
}

@end
