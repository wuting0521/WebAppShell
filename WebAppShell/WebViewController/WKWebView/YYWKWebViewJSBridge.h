//
//  YYWKWebViewJSBridge.h
//  YYMobile
//
//  Created by Bruce on 2017/4/17.
//  Copyright © 2017年 YY.inc. All rights reserved.
//

#import "WebViewJavascriptBridgeAbstract.h"
#import "YYWKWebView.h"

@interface YYWKWebViewJSBridge : WebViewJavascriptBridgeAbstract
@property (nonatomic, weak) id<YYWKWebViewUserContentDelegate> userContentDelegate;

+ (instancetype)bridgeForWebView:(YYWKWebView *)webView;
- (void)unregisterAllHandlers;

- (void)dispatchStartupMessage;

@end
