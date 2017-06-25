//
//  YYWKWebView.m
//  YYMobile
//
//  Created by Bruce on 2017/4/13.
//  Copyright © 2017年 YY.inc. All rights reserved.
//

#import "YYWKWebView.h"
#import "YYWebAppFramework.h"
#import <objc/runtime.h>
//#import "YYHTTPSConfigCore.h"
//#import "YYHTTPSUtility.h"
//#import "AlertView.h"

void ISSwizzleInstanceMethod(Class class, SEL originalSelector, SEL alternativeSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method alternativeMethod = class_getInstanceMethod(class, alternativeSelector);
    
    if(class_addMethod(class, originalSelector, method_getImplementation(alternativeMethod), method_getTypeEncoding(alternativeMethod))) {
        class_replaceMethod(class, alternativeSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, alternativeMethod);
    }
}

static NSString * const kYYWKWebViewAPI = @"YYWKWebViewAPI";

@interface YYWKWebView ()<WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) YYWebAppBridge *webAppBridge;
@property (nonatomic, strong) NSDate *startLoadTime;
@property (nonatomic, strong) NSURL *loadingURL;
@property (nonatomic, strong) WKNavigation *currentNavigation;

@end

@implementation YYWKWebView

#pragma mark - Life Cycle

+ (void) load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ISSwizzleInstanceMethod([self class], @selector(evaluateJavaScript:completionHandler:), @selector(altEvaluateJavaScript:completionHandler:));
    });
}
/*
 * fix: WKWebView crashes on deallocation if it has pending JavaScript evaluation
 */
- (void)altEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    id strongSelf = self;
    [self altEvaluateJavaScript:javaScriptString completionHandler:^(id r, NSError *e) {
        [strongSelf title];
        if (completionHandler) {
            completionHandler(r, e);
        }
    }];
}


+ (WKWebViewConfiguration *)WebViewConfiguration
{
    NSString *jsFilePath = [[NSBundle mainBundle] pathForResource:@"YYWKWebViewAPI" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:jsFilePath encoding:NSUTF8StringEncoding error:nil];
    
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addUserScript:userScript];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = controller;
    
    return configuration;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    [YYWebAppFramework sharedInstance];//调用一下YYWebAppFramework的initialize方法，以设置navigator.userAgent
    
    WKWebViewConfiguration *configuration = [YYWKWebView WebViewConfiguration];//WKWebView加载的时候就注入JS代码
    
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self.configuration.userContentController addScriptMessageHandler:self name:kYYWKWebViewAPI];//处理YYApi，与H5交互
        self.UIDelegate = self;
        self.navigationDelegate = self;
    }
    return self;
}

//- (instancetype)initWithCoder:(NSCoder *)coder //WKWebView 不支持从Nib文件加载

- (void)dealloc
{
    [self stopLoading];
    
    [self.configuration.userContentController removeScriptMessageHandlerForName:@"YYApi"];
    super.UIDelegate = nil;
    super.navigationDelegate = nil;
    
    [_webAppBridge unregisterAllModuleAPIs];
    _webAppBridge = nil;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
}

- (WKNavigation *)loadRequest:(NSURLRequest *)aRequest
{
    //发送请求之前，先带上cookie
    NSMutableDictionary *cookieDic = [NSMutableDictionary dictionary];
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookies cookies]) {
        [cookieDic setObject:cookie.value forKey:cookie.name];
    }
    
    NSMutableString *cookieValue = [NSMutableString stringWithFormat:@""];
    for (NSString *key in cookieDic) {
        NSString *appendString = [NSString stringWithFormat:@"%@=%@;", key, [cookieDic valueForKey:key]];
        [cookieValue appendString:appendString];
    }
    
    NSMutableURLRequest *request = [aRequest mutableCopy];
    [request addValue:cookieValue forHTTPHeaderField:@"Cookie"];
    
//    //修改为https请求
//    BOOL needForceHTTPS = [GetCore(YYHTTPSConfigCore) needForcedHTTPSWithURL:request.URL];
//    if (needForceHTTPS && [YYHTTPSUtility isHTTPURL:request.URL]) {
//        NSURL *httpsURL = [GetCore(YYHTTPSConfigCore) afterHTTPSProcessWithURL:request.URL];
//        request.URL = httpsURL;
//    }
    
    return [super loadRequest:request];
}

#pragma mark - Properties

- (void)setModuleAPIs:(NSArray *)moduleAPIs
{
    _moduleAPIs = moduleAPIs;
    [self.webAppBridge unregisterAllModuleAPIs];
    for (id<YYWebAppAPI>obj in moduleAPIs) {
        if ([obj conformsToProtocol:@protocol(YYWebAppAPI)]){
            if (![self.webAppBridge registerAPI:obj forModule:obj.module]){
                [YYLogger error:TWebApp message:@"Register api(%@) for module(%@) failed.", obj, obj.module];
            }
        }
    }
}

- (YYWebAppBridge *)webAppBridge
{
    if (!_webAppBridge) {
        _webAppBridge = [[YYWebAppBridge alloc] init];
    }
    return _webAppBridge;
}

#pragma mark - WKScriptMessageHandler
//处理H5调用的API
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:kYYWKWebViewAPI]) {
        if (self.userContentDelegate && [self.userContentDelegate respondsToSelector:@selector(shouldHandleUserMessage:)]) {
            if ([self.userContentDelegate shouldHandleUserMessage:message]) {
                id msg = message.body;
                if ([msg isKindOfClass:NSString.class]) {
                    [self.webAppBridge webView:self handleAPIWithURL:[NSURL URLWithString:msg]];
                }
            }
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURLRequest *request = navigationAction.request;
    
    //询问delegate是否转跳网页
    BOOL shouldStartLoad = YES;
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(webView:shouldStartLoadWithNavigationAction:)]) {
        shouldStartLoad = [self.webViewDelegate webView:self shouldStartLoadWithNavigationAction:navigationAction];
    }
    
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:request.URL.absoluteString];
    }
    
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    if (shouldStartLoad && !isFragmentJump && isHTTP && isTopLevelNavigation){
        self.loadingURL = request.URL;
        [self onLoadStarted];//开始加载网页
    }
    
    decisionHandler(shouldStartLoad ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.webViewDelegate webViewDidStartLoad:self];
    }
    
    self.currentNavigation = navigation;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.webViewDelegate webViewDidFinishLoad:self];
    }
    
    //TODO:考虑重定向等其他因素
    if ([self.currentNavigation isEqual:navigation]) {
        [self onLoadURLSuccess:YES];
        self.currentNavigation = nil;
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.webViewDelegate webView:self didFailLoadWithError:error];
    }
    
    //TODO:
    [self onLoadURLSuccess:NO];
}


- (void)onLoadStarted
{
    self.startLoadTime = [NSDate date];
}

- (void)onLoadURLSuccess:(BOOL)success
{
    NSTimeInterval loadCost = [[NSDate date] timeIntervalSinceDate:self.startLoadTime];
    [YYLogger info:TWebApp message:@"WKWebView Load page url %@ %@, costs %f", self.loadingURL, success ? @"succesfully" : @"failed", loadCost];
}

- (void)stringByEvaluatingJavaScriptFromString:(NSString *)script
{
    [self evaluateJavaScript:script completionHandler:nil];
}


#pragma mark - WKUIDelegate
//这里处理JS的alert()方法
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
//    AlertView *alertView = [[AlertView alloc]initWithTitle:nil message:message];
//    [alertView addButton:@"确定" clickBlock:^{
//        
//    }];
//    [alertView show];

    completionHandler();
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
//    AlertView *alertView = [[AlertView alloc]initWithTitle:nil message:message];
//    [alertView addButton:@"取消" clickBlock:^{
//        completionHandler(NO);
//    }];
//    [alertView addButton:@"确定" clickBlock:^{
//        completionHandler(YES);
//    }];
//    [alertView show];
}

@end
