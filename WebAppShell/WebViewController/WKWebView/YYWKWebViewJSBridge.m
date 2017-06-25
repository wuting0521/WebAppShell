//
//  YYWKWebViewJSBridge.m
//  YYMobile
//
//  Created by Bruce on 2017/4/17.
//  Copyright © 2017年 YY.inc. All rights reserved.
//

#import "YYWKWebViewJSBridge.h"

static NSString * const kYYWKWebViewJSBridge = @"YYWKWebViewJSBridge";

@interface YYWKWebViewJSBridge ()<WKScriptMessageHandler>

@end

@implementation YYWKWebViewJSBridge

+ (instancetype)bridgeForWebView:(YYWKWebView *)webView
{
    NSString *jsFilePath = [[NSBundle mainBundle] pathForResource:@"YYWKWebViewJSBridge" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:jsFilePath encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsCode injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    
    YYWKWebViewJSBridge *bridge = [[YYWKWebViewJSBridge alloc] init];
    bridge.webView = webView;
    bridge.messageHandlers = [NSMutableDictionary dictionary];
    [webView.configuration.userContentController addUserScript:userScript];
    [webView.configuration.userContentController addScriptMessageHandler:bridge name:kYYWKWebViewJSBridge];
    [bridge reset];
    
    return bridge;
}

- (void)unregisterAllHandlers
{
    [self.messageHandlers removeAllObjects];
}

- (void)dispatchStartupMessage
{
    if (self.startupMessageQueue) {
        for (id queuedMessage in self.startupMessageQueue) {
            [self _dispatchMessage:queuedMessage];
        }
        self.startupMessageQueue = nil;
    }
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:kYYWKWebViewJSBridge]) {
        
        if (self.userContentDelegate && [self.userContentDelegate respondsToSelector:@selector(shouldHandleUserMessage:)]) {
            if ([self.userContentDelegate shouldHandleUserMessage:message]) {
                id msg = message.body;
                if ([msg isKindOfClass:NSString.class] && [msg isEqualToString:kQueueHasMessage]) {
                    NSError *error;
                    [self _flushMessageQueueWithError:&error];
                    if (error) {
                        [YYLogger error:TWebApp message:@"YYWKWebViewJSBridge flushMessageQueue rise to error :%@", error];
                    }
                }
            }
        }
    }
}

@end
