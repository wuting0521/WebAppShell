//
//  WABaseAPIReflectionImpl.h
//  YY2
//
//  Created by wuwei on 14-5-20.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYWebAppAPI.h"

#define CALLBACK_AND_RETURN(p) \
if (callback) {         \
callback((p));      \
}   \
return (p);

/**
 *  反射实现invokeClientMethod:parameter:callback
 *  
 *  子类只需要按以下格式实现响应函数即可
 *  - (id)XXXX:(id)parameter callback:(YYWACallback)callback;   
 *  其中XXXX与invokeClientMethod:parameter:callback中的name对应
 */
@interface WABaseAPIReflectionImpl : NSObject <YYWebAppAPI>

@property(weak, nonatomic) UIWebView *webView;

- (id)invokeClientMethod:(NSString *)name parameter:(id)parameter callback:(YYWACallback)callback;

@end
