//
//  UIView+Loading.m
//  OnePiece
//
//  Created by qwe on 2017/4/28.
//  Copyright © 2017年 YY. All rights reserved.
//

#import "UIView+Loading.h"
#import <objc/runtime.h>

#import "YYLoadingToastView.h"
#import "UIViewUtils.h"

static char kLoadingViewTag;
static char kEmptyViewTag;
static char kOriginBackgroundColor;

@implementation UIView (Loading)

- (void)showLoadingView {
    if (![NSThread isMainThread]) {
        return;
    }
//    [self hideToastViews];
    [self hideLoadingView];
    
    YYLoadingToastView *loading = [YYLoadingToastView instantiateLoadingToast];
    [self setLoadingView:loading];
    loading.center = [self center];
    loading.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:loading];
}

- (void)hideLoadingView {
    
    YYLoadingToastView *loading = [self getLoadingView];
    if (loading) {
        [self setLoadingView:nil];
        [loading removeFromSuperview];
        loading = nil;
    }
}

#pragma mark -
//- (void)showEmptyToastView {
//    [self showEmptyToastViewWithToast:nil];
//}
//
//- (void)showEmptyToastViewWithToast:(NSString *)toast {
//    [self showEmptyToastViewWithImage:[UIImage imageNamed:@"empty_content"] toast:toast];
//}
//
//- (void)showEmptyToastViewWithImage:(UIImage *)image toast:(NSString *)toast {
//    [self showEmptyToastViewWithImage:image toast:toast offset:0 action:nil];
//}
//
//- (void)showEmptyToastViewWithImage:(UIImage *)image toast:(NSString *)toast offset:(CGFloat)offset action:(dispatch_block_t)action {
//    if (![NSThread isMainThread]) {
//        return;
//    }
//    [self hideToastViews];
//    
//    EmptyToastView *toastView = [EmptyToastView emptyToastWithImage:image toast:toast];
//    [self setEmptyToastView:toastView];
//    [self addSubview:toastView];
//    [toastView addConstraint:NSLayoutAttributeCenterY constant:offset];
//    [toastView addConstraint:NSLayoutAttributeCenterX constant:0];
//}
//
//- (void)showEmptyToastViewWithImage:(UIImage *)image toast:(NSString *)toast offset:(CGFloat)offset action:(dispatch_block_t)action backgroundColor:(UIColor *)backgroundColor {
//    [self showEmptyToastViewWithImage:image toast:toast offset:offset action:action];
//    
//    if (backgroundColor) {
//        [self setOriginBackgroundColor:self.backgroundColor];
//        self.backgroundColor = backgroundColor;
//    }
//}
//
//- (void)hideEmptyToastView {
//    EmptyToastView *empty = [self getEmptyToastView];
//    if (empty) {
//        [self setEmptyToastView:nil];
//        [empty removeFromSuperview];
//        empty = nil;
//        
//        UIColor *origin = [self originBackgroundColor];
//        if (origin) {
//            self.backgroundColor = origin;
//            [self setOriginBackgroundColor:nil];
//        }
//    }
//}
//
//- (void)hideToastViews {
//    [self hideLoadingView];
//    [self hideEmptyToastView];
//}

#pragma mark - Getter & Setter

- (void)setLoadingView:(YYLoadingToastView *)toast {
    
    objc_setAssociatedObject(self, &kLoadingViewTag,
                             toast, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (YYLoadingToastView *)getLoadingView {
    return objc_getAssociatedObject(self, &kLoadingViewTag);
}

//- (void)setEmptyToastView:(EmptyToastView *)empty {
//    objc_setAssociatedObject(self, &kEmptyViewTag, empty, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}
//
//- (EmptyToastView *)getEmptyToastView {
//    return objc_getAssociatedObject(self, &kEmptyViewTag);
//}

- (void)setOriginBackgroundColor:(UIColor *)color {
    objc_setAssociatedObject(self, &kOriginBackgroundColor, color, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIColor *)originBackgroundColor {
    return objc_getAssociatedObject(self, &kOriginBackgroundColor);
}
@end
