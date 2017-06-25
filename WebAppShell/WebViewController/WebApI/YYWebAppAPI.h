//
//  YYWebAppAPI.h
//  YYFoundation
//
//  Created by wuwei on 14-5-9.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^YYWACallback)(id parameter);

@protocol YYWebAppAPI <NSObject>

@property (nonatomic, readonly, strong) NSString *module;

- (id)invokeClientMethod:(NSString *)name parameter:(id)parameter callback:(YYWACallback)callback;
- (void)setWebView:(UIWebView *)webView;

@end
