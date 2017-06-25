//
//  WAUserInterfaceAPI.h
//  YYFoundation
//
//  Created by wuwei on 14-5-4.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WABaseAPIReflectionImpl.h"
#import "YYWebAppAPI.h"

extern NSString * const  WABindPhoneSuccessNotification;

@class WAUserInterfaceAPI;
/*
 * WAUserInterfaceAPI的UI Context
 *
 * 与ui上下文相关的操作(如push, pop)均应当由其Context完成
 * (Context通常是包含WebView的ViewController)
 *
 */
@protocol WAUserInterfaceContext <NSObject>

@optional

- (void)reloadWebView;

- (void)userInterfaceAPI:(WAUserInterfaceAPI *)api gotoURI:(NSString *)uri;
- (void)showLoginDialogWithUserInterfaceAPI:(WAUserInterfaceAPI *)api;
- (void)userInterfaceAPI:(WAUserInterfaceAPI *)api
shouldPushViewController:(UIViewController *)viewController;
- (BOOL)shouldPopWithUserInterfaceAPI:(WAUserInterfaceAPI *)api;
- (void)closeAllWindowWithUserInterfaceAPI:(WAUserInterfaceAPI *)api;
- (void)showBackBtnWithUserInterfaceAPI:(WAUserInterfaceAPI *)api;
- (void)hideBackBtnWithUserInterfaceAPI:(WAUserInterfaceAPI *)api;
- (void)shareWithUserInterfaceAPI:(WAUserInterfaceAPI *)api;
- (void)setNavigationBarTitleWithUserInterfaceAPI:(WAUserInterfaceAPI *)api title:(NSString*)title;

// 显示／隐藏 loading
- (void)loadingAnimation:(BOOL)show timeout:(NSInteger)timeout;

// 活动条设置frame
- (BOOL)setLayout:(id)parameter;

// 显示活动条
- (BOOL)showAct:(id)parameter;

// 活动条弹窗
- (void)openActWindow:(id)parameter;
- (void)closeActWindow;

- (NSString *)getCurrentVideoMode;

- (void)setPageBackMode:(id)parameter;

//回调JS
- (void)onCallBackJavaScript:(NSString *)js;


/**
 *  用于显示动画的区域，给 playAnimation 用
 */
- (UIView *)animationAreaViewWithUserInterfaceAPI:(WAUserInterfaceAPI *)api;

/**
 *  更新 WebView 的高度，主要用于直播间内的活动条
 */
- (void)updateWebViewHeight:(NSString *)actId height:(CGFloat)height;

/**
 *  更新 WebView 的宽度
 */
- (void)updateWebViewWidth:(NSString *)actId width:(CGFloat)width;

- (void)onZMCerticateWithParams:(NSDictionary *)certifyParams;

- (void)setPullRefreshEnable:(BOOL)canPull;

@end

/**
 *  module: ui
 */
@interface WAUserInterfaceAPI : WABaseAPIReflectionImpl

- (instancetype)initWithContext:(id<WAUserInterfaceContext>)context;

-(id)getContext;

@end

@interface WAUserInterfaceURIAuthorityEntity : NSObject

@property (nonatomic, strong) NSString *authority;
@property (nonatomic, strong) NSDictionary *pathes;

@end

