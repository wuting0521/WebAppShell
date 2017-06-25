//
//  YYWebAppFramework.m
//  YYFoundation
//
//  Created by wuwei on 14-5-9.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import "YYWebAppFramework.h"
#import "NSURL+Parameters.h"
#import "YYUtility.h"
#import <WebKit/WebKit.h>
#import "AppConfig.h"


static NSString * const kYYWebAppFrameworkProtocolScheme = @"yyapi";

static NSString * const kOpenTaobaoScheme = @"tbopen";
static NSString * const kTaobaoSchemeUrl = @"taobao://";


#pragma mark - YYWebAppFramework Protected

@interface YYWebAppFramework ()

@end

#pragma mark - YYWebAppBridge

@interface YYWebAppBridge () <UIWebViewDelegate>

- (instancetype)initWithWebView:(UIWebView *)webView
                webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate;

@property (nonatomic, weak) YYWebAppFramework *webAppFramework;

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) id<UIWebViewDelegate> webViewDelegate;

@property (nonatomic, assign) NSUInteger numRequestsLoading;

@property (nonatomic, strong, readonly) NSMutableDictionary *moduleAPIs;

- (void)_injectBridgeJavascript:(UIWebView *)webView;

- (id)_invokeWebMethod:(NSString *)name
             parameter:(id)parameter;

- (id)_invokeClientMethod:(NSString *)module
                     name:(NSString *)name
                parameter:(id)parameter
                 callback:(YYWACallback)callback;
- (id<YYWebAppAPI>)_apiForModule:(NSString *)module;

@end

#pragma mark - YYWebAppFramework Implementation

@implementation YYWebAppFramework
{
@private
    
}

+ (void)initialize
{
    if (self == [YYWebAppFramework self])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            //            [NSURLCache setSharedURLCache:[[WAURLCache alloc] init]];
            
            UIWebView *webView = [[UIWebView alloc] init];
            NSString *originalUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
//            if ([originalUA rangeOfString:@"Yijian"].location == NSNotFound)
//            {
//                // modify UserAgent by appending YY/{AppVersion}
//                NSString *userAgentWithYYVersion = [originalUA stringByAppendingFormat:@"Build%@",
//                                                    [YYUtility appBuild]];
//                
//                NSInteger netStatus = [YYUtility reachableStatus];
//                NSString *netString = @"";
//                if (netStatus == 1) {
//                    netString = @"WIFI";
//                } else if (netStatus == 2) {
//                    netString = @"2G";
//                } else if (netStatus == 3) {
//                    netString = @"3G";
//                } else if (netStatus == 4) {
//                    netString = @"4G";
//                }
//                NSString *temp = [originalUA stringByAppendingFormat:@" Yijian/%@ Environment/%@ NetType/%@ UserMode/%@",
//                                                    [YYUtility appVersion], EnvironmentType()==0?@"Online":@"Test", netString, [[AuthSrv sharedInstance] getUserId]==0?@"Guest":@"Registered"]
//                ;
//                userAgentWithYYVersion = [userAgentWithYYVersion stringByAppendingString:temp];
//                
//                NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:userAgentWithYYVersion, @"UserAgent", nil];
//                [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
//            }
        });
    }
}

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (YYWebAppBridge *)instantiateBridgeForWebView:(UIWebView *)webView
                                webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
                                     moduleAPIs:(NSArray *)moduleAPIs
{
    YYWebAppBridge *bridge = [[YYWebAppBridge alloc] initWithWebView:webView
                                                     webViewDelegate:webViewDelegate];
    for (id<YYWebAppAPI> obj in moduleAPIs)
    {
        if ([obj conformsToProtocol:@protocol(YYWebAppAPI)])
        {
            if (![bridge registerAPI:obj forModule:obj.module])
            {
                [YYLogger error:TWebApp message:@"Register api(%@) for module(%@) failed.", obj, obj.module];
            }
        }
    }
    
    return bridge;
}

#pragma mark - Internal Properties

@end

#pragma mark - YYWebAppBridge Implementation

@implementation YYWebAppBridge

@synthesize moduleAPIs = _moduleAPIs;

- (instancetype)initWithWebView:(UIWebView *)webView
                webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
{
    self = [super init];
    if (self) {
        webView.delegate = self;
        self.webView = webView;
        self.webViewDelegate = webViewDelegate;
        
        /**
         *  Injecting WAJavascriptBridge_iOS.js
         */
        [self _injectBridgeJavascript:self.webView];
        
        _moduleAPIs = [NSMutableDictionary dictionary];
    }
    return self;
}

//WKWebView的webAppBridge使用这个初始化方法，不需要设置webViewDelegate属性，暂时不处理webView属性
-(instancetype)init
{
    self = [super init];
    if (self) {
        _moduleAPIs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterAllModuleAPIs];
    self.webView = nil;
}

- (BOOL)registerAPI:(id<YYWebAppAPI>)api forModule:(NSString *)module
{
    if (module == nil || api == nil) {
        return NO;
    }
    
    @synchronized(self.moduleAPIs) {
        self.moduleAPIs[module] = api;
        return YES;
    }
}

- (void)unregisterAPIForModule:(NSString *)module
{
    @synchronized(self.moduleAPIs) {
        [self.moduleAPIs removeObjectForKey:module];
    }
}

- (void)unregisterAllModuleAPIs
{
    @synchronized(self.moduleAPIs) {
        [self.moduleAPIs removeAllObjects];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (webView != self.webView) {
        return;
    }
    
    self.numRequestsLoading++;
    
    __strong typeof(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [strongDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView != self.webView) {
        return;
    }
    self.numRequestsLoading--;
    if (self.numRequestsLoading == 0 && ![[webView stringByEvaluatingJavaScriptFromString:@"typeof window.YYApiCore == 'object'"] isEqualToString:@"true"]) {
        [self _injectBridgeJavascript:webView];
    }
    
    __strong typeof(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [strongDelegate webViewDidFinishLoad:webView];
    }
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (webView != self.webView) {
        return;
    }
    self.numRequestsLoading--;
    __strong typeof(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [strongDelegate webView:webView didFailLoadWithError:error];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (webView != self.webView || (navigationType == UIWebViewNavigationTypeOther && [request.URL.absoluteString isEqualToString:@"about:blank"]))
    {
        return YES;
    }
    
    NSURL *url = request.URL;
    __strong __typeof__(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    
    //活动条类型
    NSString *activityType = (NSString*)[self.webView stringByEvaluatingJavaScriptFromString:[self _safeStaticFunction:@"activityType"]];
    NSString *schemeStr = [(NSString *)[self.webView stringByEvaluatingJavaScriptFromString:[self _safeStaticFunction:@"ecommerce_AppScheme"]] lowercaseString];
    NSArray *schemes;
    if (schemeStr && ![schemeStr isEqualToString:@""]) {
        schemes = [schemeStr componentsSeparatedByString:@","];
    }
    
    if ([url.scheme isEqualToString:kYYWebAppFrameworkProtocolScheme]) {
        //普通的运营活动条，
#if OFFICIAL_RELEASE
        
        if (![[self.webView.request.mainDocumentURL host] hasSuffix:@"yy.com"] &&
            ![[self.webView.request.mainDocumentURL host] hasSuffix:@"1931.com"] &&
            ![[self.webView.request.mainDocumentURL host] hasSuffix:@"duowan.com"]) {
            
            NSString *host = (NSString *)[self.webView stringByEvaluatingJavaScriptFromString:@"window.location.host"];
            
            //YYELTWebView 为秀场专用webView
            if (![self.webView isKindOfClass:NSClassFromString(@"YYELTWebView")]) {
                if (![host isKindOfClass:[NSString class]]) {
                    return NO;
                }
                if (![host hasSuffix:@"yy.com"] && ![host hasSuffix:@"1931.com"]) {
                    return NO;
                }
            } else {
                
                NSString *localHost = (NSString *)[self.webView stringByEvaluatingJavaScriptFromString:@"window.getLocalHost()"];
                
                if (![localHost isKindOfClass:[NSString class]] || ![localHost hasSuffix:@"yy.com"] ) {
                    if (![host isKindOfClass:[NSString class]]) {
                        return NO;
                    }
                    if (![host hasSuffix:@"yy.com"] && ![host hasSuffix:@"1931.com"]) {
                        return NO;
                    }
                }
            }
        }
        
#endif
        
        if ([url.host isEqualToString:@"load"])
        {
            [self _injectBridgeJavascript:self.webView];
            return NO;
        }
        
        [self webView:webView handleAPIWithURL:url];
        return NO;
        
    }
    else if (schemes && [schemes containsObject:[url.scheme lowercaseString]]){
        //电商活动条，走活动条框架，但又有不同的逻辑处理
        
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            
            [[UIApplication sharedApplication] openURL:url];
            
        }else{
            
            [self.webView stringByEvaluatingJavaScriptFromString:[self _safeStaticFunction:@"ecommerce_H5Jump" withParam:url.absoluteString]];
        }
        return NO;
        
    }else if([activityType isEqualToString:@"Ecommerce"]) {
        
        NSString *invalidHostString = (NSString *)[self.webView stringByEvaluatingJavaScriptFromString:[self _safeStaticFunction:@"ecommerce_invalidSeeotherHost"]];
        
        NSArray *invalidHosts = [invalidHostString componentsSeparatedByString:@","];
        
        if (invalidHosts && invalidHosts.count>0) {
            if([invalidHosts containsObject:url.host])
                return NO;
        }
        
    }
    else if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        
        return [strongDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        
    }
    
    
    return YES;
}

- (void)webView:(id)webView handleAPIWithURL:(NSURL *)url
{
    /**
     *  Example: yyapi://ui/push?p={uri:'xxx'}&cb=callback
     *      - Module: ui
     *      - Name: Push
     *      - Parameter: {uri:'xxx'}
     */
    NSString *module = url.host;
    NSString *json = url[@"p"];
    NSString *callback = url[@"cb"];
    NSArray *pathComponents = url.pathComponents;
    if (pathComponents.count == 2)
    {
        NSString *name = [pathComponents objectAtIndex:1];
        
        NSError *parseError;
        NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObject =[NSJSONSerialization JSONObjectWithData:jsonData
                                                       options:NSJSONReadingAllowFragments
                                                         error:&parseError];
        
        YYWACallback callbackBlock = NULL;
        if (callback) {
            callbackBlock = ^(id returnValue) {
                returnValue = returnValue ? : NSNull.null;
                NSDictionary *result = @{@"result": returnValue};
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
                NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                
                NSString *javascript = [NSString stringWithFormat:@"YYApiCore.invokeWebMethod(\"%@\", %@.result);", callback, json];
                
                //WKWebView与UIWebView调用的方法不同
                if ([webView isKindOfClass:UIWebView.class]) {
                    [YYLogger debug:TWebApp message:@"[+/-] UIWebView Execute javascript: %@.", javascript];
                    [webView stringByEvaluatingJavaScriptFromString:javascript];
                } else if ([webView isKindOfClass:WKWebView.class]){
                    [YYLogger debug:TWebApp message:@"[+/-] WKWebView Execute javascript: %@.", javascript];
                    [webView evaluateJavaScript:javascript completionHandler:nil];
                }
            };
        }
        
        // Call module methods
        id returnValue = [self _invokeClientMethod:module
                                              name:name
                                         parameter:jsonObject
                                          callback:callbackBlock];
        
        //如果是WKWebView，不支持直接调用JS设置返回值，只能通过上面的callback与H5通信
        if ([webView isKindOfClass:[WKWebView class]]) {
            return;
        }
        
        returnValue = returnValue ? : NSNull.null;
        NSDictionary *result = @{@"result": returnValue};
        jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
        json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        // Set return value synchronously
        NSString *javascript = [NSString stringWithFormat:@"YYApiCore.__RETURN_VALUE__ = %@;", json];
        [YYLogger debug:TWebApp message:@"[+/-] Execute javascript: %@.", javascript];
        [webView stringByEvaluatingJavaScriptFromString:javascript];
    }
    else
    {
        [YYLogger error:TWebApp message:@"[YYWebAppFramework] Invalid yymobile url."];
    }
    
}


//- (void)webView:(UIWebView *)webView didCreateJavascriptContext:(JSContext *)context
//{
//    context[@"YYApiCore"] = [YYApiCore sharedObject];
//}

//安全地调用document的静态函数
- (NSString*)_safeStaticFunction:(NSString*)function{
    
    return [self _safeStaticFunction:function withParam:nil];
}
- (NSString*)_safeStaticFunction:(NSString*)function withParam:(NSString*)param{
    
    NSString *safeCall;
    
    if (param) {
        safeCall = [NSString stringWithFormat:@"if (typeof window.%@ == 'function'){ \
                    window.%@(\'%@\')  \
                    }",function,function,param];
        
    }else{
        safeCall = [NSString stringWithFormat:@"if (typeof window.%@ == 'function'){ \
                    window.%@()  \
                    }",function,function];
        
    }
    
    return safeCall;
}


- (void)_injectBridgeJavascript:(UIWebView *)webView
{
    //    NSString *bundlePath = [YYUtility pathForMobileFrameworkResourceBundle];
    NSString *filePath = [[NSBundle mainBundle]
                          pathForResource:@"WAJavascriptBridge_iOS"
                          ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:filePath
                                             encoding:NSUTF8StringEncoding error:nil];
    [webView stringByEvaluatingJavaScriptFromString:js];
}

/**
 *  @Brief 调用一个Web方法(Javascript)
 *  iOS上, 所有Objective-C调用Javascript均采用同步方式, 因此没有callback
 */
- (id)_invokeWebMethod:(NSString *)name
             parameter:(id)parameter
{
    return nil;
}

/**
 *  @Brief 调用一个Native方法
 *  同步调用
 */
- (id)_invokeClientMethod:(NSString *)module
                     name:(NSString *)name
                parameter:(id)parameter
                 callback:(YYWACallback)callback
{
    id<YYWebAppAPI> api = [self _apiForModule:module];
    
    // 如果 api 对象有 setWebView 接口，则把当前 webView 设置过去   by zhenby
    // TODO:WKWebView
    if (self.webView && [api respondsToSelector:@selector(setWebView:)]) {
        [api setWebView:self.webView];
    }
    
    id result = [api invokeClientMethod:name parameter:parameter callback:callback];
    return result;
}

- (id<YYWebAppAPI>)_apiForModule:(NSString *)module
{
    id obj = [self.moduleAPIs objectForKey:module];
    return [obj conformsToProtocol:@protocol(YYWebAppAPI)] ? obj : nil;
}

@end
