//
//  YYWKWebView.h
//  YYMobile
//
//  Created by Bruce on 2017/4/13.
//  Copyright © 2017年 YY.inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol YYWKWebViewUserContentDelegate <NSObject>
- (BOOL)shouldHandleUserMessage:(WKScriptMessage *)message;
@end

@class YYWKWebView;
@protocol YYWKWebViewDelegate <NSObject>
- (BOOL)webView:(YYWKWebView *)webView shouldStartLoadWithNavigationAction:(WKNavigationAction *)navigationAction;
- (void)webViewDidStartLoad:(YYWKWebView *)webView;
- (void)webViewDidFinishLoad:(YYWKWebView *)webView;
- (void)webView:(YYWKWebView *)webView didFailLoadWithError:(NSError *)error;
@end


@interface YYWKWebView : WKWebView
@property (nonatomic, strong) NSArray *moduleAPIs;
@property (nonatomic, weak) id<YYWKWebViewDelegate> webViewDelegate;
@property (nonatomic, weak) id<YYWKWebViewUserContentDelegate> userContentDelegate;
- (void)stringByEvaluatingJavaScriptFromString:(NSString *)script;
@end
