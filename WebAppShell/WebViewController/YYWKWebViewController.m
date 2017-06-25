//
//  YYWKWebViewController.m
//  YYMobile
//
//  Created by Bruce on 2017/4/13.
//  Copyright © 2017年 YY.inc. All rights reserved.
//

#import "YYWKWebViewController.h"
#import "UIView+Toast.h"
#import "UIViewUtils.h"
#import "WAUserInterfaceAPI.h"
#import "NSDictionary+Safe.h"
#import "UIView+Loading.h"
#import "UIViewController+YYViewControllers.h"

@interface YYWKWebViewController ()<YYWKWebViewDelegate, YYWKWebViewUserContentDelegate, WAUserInterfaceContext, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong) NSArray *moduleAPIs;
@property (atomic, assign) BOOL isLoading;
@property (nonatomic, strong) NSDictionary *barButtonIdMap;

@property (nonatomic, strong) NSDictionary *webPageBackMode;

@property(nullable,nonatomic,weak) id <UIGestureRecognizerDelegate> popDelegate; // the gesture recognizer's delegate

@end

@implementation YYWKWebViewController

#pragma mark - Life Cycle

- (instancetype)init
{
    return [[YYWKWebViewController alloc] initWithURL:nil];
}

- (instancetype)initWithAddress:(NSString *)address
{
    return [[YYWKWebViewController alloc] initWithURL:[NSURL URLWithString:address]];
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super initWithNibName:@"YYWKWebViewController" bundle:[NSBundle mainBundle]];
    if (self) {
        self.url = url;
        self.feature = WebViewFeature_UsualFeature ;
        self.webView = [[YYWKWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupWebView];
    
    [self updateToolbar];
    
    [self setupJSBridge];
    
    [self updateFeatures];
    
    self.navigationItem.title = self.webTitle;
    
    [self loadURL:self.url];
    
    self.canPullRefresh = YES;
    
    [self updateNavigation];
}

- (void)updateNavigation {
    
    UIBarButtonItem *negativeSpacerLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negativeSpacerLeft setWidth:-4];
    
    UIBarButtonItem* backBarButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(onExitButtonClicked:)];
    self.navigationItem.leftBarButtonItems = @[negativeSpacerLeft, backBarButton];
}

- (void)onExitButtonClicked:(id)sender {
    
    BOOL popNavigation = NO;
    
    NSString *backMode = [self.webPageBackMode stringForKey:@"backMode"];
    if ([backMode isEqualToString:@"exit"]) {
        
        popNavigation = YES;
    } else if ([backMode isEqualToString:@"history"]) {
        
        if ([self.webView canGoBack]) {
            [self.webView goBack];
        } else {
            popNavigation = YES;
        }
    } else if ([backMode isEqualToString:@"layer"]) {
        NSString *lastUrl = [self.webPageBackMode stringForKey:@"lastLayUrl"];
        if (lastUrl) {
            [self loadURL:[NSURL URLWithString:lastUrl]];
        } else {
            popNavigation = YES;
        }
    } else {
        popNavigation = YES;
    }
    if (popNavigation) {
        [self.navigationController popViewControllerAnimated:YES];
        if (self.navigationController.viewControllers.firstObject == self) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)setupWebView
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    YYWKWebView *webView = self.webView;
    [self.view insertSubview:webView belowSubview:self.toolBar];
    
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(webView)]];
    
    webView.backgroundColor = [UIColor clearColor];
    webView.webViewDelegate = self;
    webView.userContentDelegate = self;
    webView.moduleAPIs = self.moduleAPIs;
}

- (void)setupJSBridge
{
    //修改了WebViewJavascriptBridgeAbstract以支持WKWebView
    self.webViewJSBridge = [YYWKWebViewJSBridge bridgeForWebView:self.webView];
    self.webViewJSBridge.userContentDelegate = self;
    self.webViewJSBridge.messageHandler = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        responseCallback(@"Response for message from ObjC");
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
    _webView.webViewDelegate = nil;
    [_webView stopLoading];
    _webView.moduleAPIs = nil;
    _webView = nil;
}

- (void)setWebTitle:(NSString *)title
{
    if (![_webTitle isEqualToString:title]){
        _webTitle = title;
        if (self.isViewLoaded){
            self.navigationItem.title = title;
        }
    }
}

- (void)loadURL:(NSURL *)url
{
    if (url) {
        [self.webView showLoadingView];
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        self.url = url;
    }
}

- (void)reload
{
    if (self.url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

- (void)loadHTMLString:(NSString *)string
{
    self.url = nil;
    [self.webView loadHTMLString:string baseURL:[[NSBundle mainBundle] bundleURL]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.navigationController.viewControllers.count > 1) { // 记录系统返回手势的代理
        _popDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
//    WADataAPI *dataAPI = [WADataAPI sharedInstance];
//    [dataAPI callReloadCallback];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self yy_viewDidAppear];
    if (self.isNeedRefresh) {
        if (self.webView) {
            [self.webView reload];
        }
    }
    if (self.isNeedRefreshPart) {
        if (self.webView) {
            [self onCallBackJavaScript:@"reshPart()"];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        if (self.isNeedPreRefresh) {
            self.isNeedPreRefresh = NO;
        }
        if (self.isNeedPreRefreshPart) {
            self.isNeedPreRefreshPart = NO;
        }
    }
    
    [super viewWillDisappear:animated];
    [self yy_viewWillDisappear];
    
    self.navigationController.interactivePopGestureRecognizer.delegate = _popDelegate;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - UIGesturePoPRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if (self.navigationController.childViewControllers.count > 1) {
        
        BOOL popNavigation = NO;
        NSString *backMode = [self.webPageBackMode stringForKey:@"backMode"];
        if ([backMode isEqualToString:@"exit"]) {
            
            popNavigation = YES;
        } else if ([backMode isEqualToString:@"history"]) {
            
            if ([self.webView canGoBack]) {
                
            } else {
                popNavigation = YES;
            }
        } else if ([backMode isEqualToString:@"layer"]) {
            NSString *lastUrl = [self.webPageBackMode stringForKey:@"lastLayUrl"];
            if (lastUrl) {
                
            } else {
                popNavigation = YES;
            }
        } else {
            popNavigation = YES;
        }
        return popNavigation;
        
    } else {
        return NO;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    if ([self preferredNavigationBarHidden]) {
        return UIStatusBarStyleDefault;
    }
    
    return UIStatusBarStyleDefault;
    
}

- (void)setCanPullRefresh:(BOOL) canPullRefresh {
    // 下拉刷新处理
//    if (canPullRefresh != _canPullRefresh){
//        _canPullRefresh = canPullRefresh;
//        __weak __typeof__(self) sself = self;
//        if (canPullRefresh){
//            dispatch_async(dispatch_get_main_queue(), ^{
//                
//                [sself.webView.scrollView addPullToRefreshWithActionHandler:^{
//                    [sself.webView reload];
//                }];
//                
//                sself.webView.scrollView.customRefreshHeader.hidden = NO;
//            });
//        } else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                //这里hidden隐藏动画，enabled为NO不会回调Block，都要设置
//                sself.webView.scrollView.customRefreshHeader.hidden = YES;
//            });
//        }
//    }
    
}

#pragma mark - YYWKWebViewDelegate

- (void)webViewDidStartLoad:(YYWKWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.isLoading = YES;
    [self updateToolbar];
}

- (void)webViewDidFinishLoad:(YYWKWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self.webViewJSBridge dispatchStartupMessage];
    
    if ([self shouldHandleLoading]) {
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.webView hideLoadingView];
        });
    } else {
        [self.webView hideLoadingView];
    }
    
    //获取网页标题
    __weak __typeof(self)weakSelf = self;
    [_webView evaluateJavaScript:@"document.title" completionHandler:^(id result, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NSString *documentTitle = nil;
        if ([result isKindOfClass:[NSString class]]) {
            documentTitle = result;
        }
        strongSelf.webTitle = documentTitle;
    }];
    self.isLoading = NO;
    [self updateToolbar];
    
//    if (self.webView.scrollView.customRefreshHeader && !self.webView.scrollView.customRefreshHeader.hidden) {
//        [self.webView.scrollView.customRefreshHeader endRefreshing];
//    }
}

- (void)webView:(YYWKWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.isLoading = NO;
    [self updateToolbar];
    if ([self shouldHandleLoading]) {
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.webView hideLoadingView];
        });
    } else {
        [self.webView hideLoadingView];
    }
    
    [self.webView evaluateJavaScript:@"document.body.innerHTML" completionHandler:^(id result, NSError *error) {
        NSString *html = nil;
        if ([result isKindOfClass:[NSString class]]) {
            html = result;
        }
    }];
//    if (self.webView.scrollView.customRefreshHeader && ![self.webView.scrollView.customRefreshHeader isHidden]) {
//        [self.webView.scrollView.customRefreshHeader endRefreshing];
//    }
}

- (BOOL)webView:(YYWKWebView *)webView shouldStartLoadWithNavigationAction:(WKNavigationAction *)navigationAction
{
    // iTunes Store Link
    if([self hasFeature:WebViewFeature_iTunesStoreSupport] && [navigationAction.request.URL.host hasSuffix:@"itunes.apple.com"]) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        return NO;
    }
    return YES;
}

- (BOOL)shouldHandleLoading
{
    NSString *host = _url.host;
    //下面的域名才能使用Web接口
    if (![host hasSuffix:@"yijian-test.yy.com"] && ![host hasSuffix:@"yijian-preview.yy.com"] && ![host hasSuffix:@"dev.yijian.yy.com"] && ![host hasSuffix:@"legox.yy.com"] && ![host hasSuffix:@"yijian.yy.com"]) {
        return NO;
    }
    return YES;
}

#pragma mark - YYWKWebViewUserContentDelegate

- (BOOL)shouldHandleUserMessage:(WKScriptMessage *)message
{
#if OFFICIAL_RELEASE
    NSURL *url = message.frameInfo.request.URL;
    NSString *host = url.host;
    //下面的域名才能使用Web接口
    if (![host hasSuffix:@"yy.com"] && ![host hasSuffix:@"1931.com"] && ![host hasSuffix:@"duowan.com"]) {
        return NO;
    }
#endif
    return YES;
}

#pragma mark - ToolBar

- (void)updateToolbar
{
    if ([self hasFeature:WebViewFeature_WebNavigationSupport]) {
        self.backBarButtonItem.enabled = self.webView.canGoBack;
        self.forwardBarButtonItem.enabled = self.webView.canGoForward;
        
        UIBarButtonItem *refreshStopBarButtonItem = self.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        fixedSpace.width = 20.0f;
        NSArray *items = [NSArray arrayWithObjects:
                          self.backBarButtonItem,
                          fixedSpace,
                          self.forwardBarButtonItem,
                          flexibleSpace,
                          refreshStopBarButtonItem,
                          nil];
        
        self.toolBar.barStyle = self.navigationController.navigationBar.barStyle;
        self.toolBar.tintColor = [UIColor whiteColor];
        [self.toolBar setItems:items];
        [self.toolBar setHidden:NO];
        UIEdgeInsets insets = self.webView.scrollView.contentInset;
        insets.bottom = self.toolBar.height;
        self.webView.scrollView.contentInset = insets;
        self.webView.scrollView.scrollIndicatorInsets = insets;
    }
    else
    {
        [self.toolBar setItems:nil];
        [self.toolBar setHidden:YES];
        UIEdgeInsets insets = self.webView.scrollView.contentInset;
        insets.bottom = 0;
        self.webView.scrollView.contentInset = insets;
        self.webView.scrollView.scrollIndicatorInsets = insets;
    }
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!_backBarButtonItem) {
        _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"YYWebViewController.bundle/back"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(onGoback:)];
        _backBarButtonItem.width = 18.0f;
        _backBarButtonItem.tintColor = [UIColor colorWithHexString:@"#FAC200"];
    }
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!_forwardBarButtonItem) {
        _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"YYWebViewController.bundle/forward"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(onGoForward:)];
        _forwardBarButtonItem.width = 18.0f;
        _forwardBarButtonItem.tintColor = [UIColor colorWithHexString:@"#FAC200"];
    }
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!_refreshBarButtonItem) {
        _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefresh:)];
        _refreshBarButtonItem.tintColor = [UIColor colorWithHexString:@"#BBBBBB"];
    }
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!_stopBarButtonItem) {
        _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(onStop:)];
        _stopBarButtonItem.tintColor = [UIColor colorWithHexString:@"#BBBBBB"];
    }
    return _stopBarButtonItem;
}

- (void)onGoback:(id)sender
{
    [self.webView goBack];
}

- (void)onGoForward:(id)sender
{
    [self.webView goForward];
}

- (void)onRefresh:(id)sender
{
    [self.webView reload];
}

- (void)onStop:(id)sender
{
    [self.webView stopLoading];
    [self updateToolbar];
}

#pragma mark - Features

- (void)setFeature:(WebViewFeature)feature
{
    if (_feature != feature) {
        _feature = feature;
        [self updateFeatures];
    }
    return;
}

- (BOOL)hasFeature:(WebViewFeature)feature
{
    return self.feature & feature;
}

- (void)updateFeatures
{
    [self updateToolbar];
    
    if ([self hasFeature:WebViewFeature_JavascriptAPISupport]) {
        NSArray *moduleAPIs = @[
                                [[WAUserInterfaceAPI alloc] initWithContext:self]];
        self.moduleAPIs = moduleAPIs;
    }
    else
    {
        self.moduleAPIs = @[];
    }
}

#pragma mark - WAUserInterfaceContext

- (void)userInterfaceAPI:(WAUserInterfaceAPI *)api shouldPushViewController:(UIViewController *)viewController
{
    if (viewController) {
        [self safePushViewController:viewController animated:YES];
    }
}

- (void)onCallBackJavaScript:(NSString *)js {
    
    if (js && js.length > 0) {
        if ([[NSThread currentThread] isMainThread]) {
            [self.webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:)
                                           withObject:js
                                        waitUntilDone:NO];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:)
                                               withObject:js
                                            waitUntilDone:NO];
            });
        }
    }
}

- (void)reloadWebView {
    [self.webView reload];
}

- (void)setPageBackMode:(id)parameter {
    
    self.webPageBackMode = [NSDictionary dictionaryWithDictionary:parameter];
}

- (void)setPullRefreshEnable:(BOOL)canPull {
    self.canPullRefresh = canPull;
}

- (void)loadingAnimation:(BOOL)show timeout:(NSInteger)timeout {
    
    if (show) {
        [self.webView showLoadingView];
        if (timeout > 0 && timeout < 15000) {
            __weak __typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.webView hideLoadingView];
            });
        }
    } else {
        [self.webView hideLoadingView];
    }
}

#pragma mark
- (UIImage *)preferredNavigationBarBackgroundImageForBarMetrics:(UIBarMetrics)barMetrics
{
    return [UIImage new];
}

- (UIColor *)preferredNavigationBarBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIImage *)preferredNavigationBarShadowImage
{
    return [UIImage new];
}

@end
