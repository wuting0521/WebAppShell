//
//  YYWebAppFramework.h
//  YYFoundation
//
//  Created by wuwei on 14-5-9.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WAUserInterfaceAPI.h"

@protocol YYWebAppAPI;

@class WADeviceAPI;
@class WAUserInterfaceAPI;

typedef void(^WAFResponseCallback)(id responseData);
typedef void(^WAFHandler)(NSDictionary *jsonObject, WAFResponseCallback responseCallback);

@interface YYWebAppBridge : NSObject <UIWebViewDelegate>

- (BOOL)registerAPI:(id<YYWebAppAPI>)api forModule:(NSString *)module;
- (void)unregisterAPIForModule:(NSString *)module;
- (void)unregisterAllModuleAPIs;
- (void)webView:(id)webView handleAPIWithURL:(NSURL *)url;

@end

@interface YYWebAppFramework : NSObject

+ (instancetype)sharedInstance;

/**
 *  WebAppBridge Creation
 */
- (YYWebAppBridge *)instantiateBridgeForWebView:(UIWebView *)webView
                                webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
                                     moduleAPIs:(NSArray *)moduleAPIs;

@end
