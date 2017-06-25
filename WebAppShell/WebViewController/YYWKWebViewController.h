//
//  YYWKWebViewController.h
//  YYMobile
//
//  Created by Bruce on 2017/4/13.
//  Copyright © 2017年 YY.inc. All rights reserved.
//

#import "YYViewController.h"

#import "YYWKWebView.h"
#import "YYWKWebViewJSBridge.h"

typedef NS_ENUM(NSUInteger, WebViewFeature)
{
    WebViewFeature_JavascriptAPISupport = 1 << 0,
    WebViewFeature_WebNavigationSupport = 1 << 1,
    WebViewFeature_iTunesStoreSupport = 1 << 2,
    
    WebViewFeature_DefaultFeature = WebViewFeature_WebNavigationSupport | WebViewFeature_iTunesStoreSupport,
    WebViewFeature_NoneFeature = 0,
    WebViewFeature_AllFeatures = WebViewFeature_JavascriptAPISupport | WebViewFeature_WebNavigationSupport | WebViewFeature_iTunesStoreSupport,
    WebViewFeature_UsualFeature = WebViewFeature_JavascriptAPISupport | WebViewFeature_iTunesStoreSupport,//支持JS和Itunes跳转，无工具条,下拉刷新
};


@interface YYWKWebViewController : YYViewController

@property (weak, nonatomic) IBOutlet UIToolbar *toolBar; //底部工具栏

@property (nonatomic, assign) WebViewFeature feature;   // default is WebViewFeature_DefaultFeature

@property (nonatomic, strong) YYWKWebViewJSBridge *webViewJSBridge;
@property (nonatomic, strong) YYWKWebView *webView;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *webTitle;
@property (nonatomic, assign) BOOL canPullRefresh; //是否下拉刷新
@property (nonatomic, assign) BOOL isNeedRefresh; //点击返回到当前页面是否刷新
@property (nonatomic, assign) BOOL isNeedRefreshPart; //点击返回到当前页面是否局部刷新
@property (nonatomic, assign) BOOL isNeedPreRefresh; // 是否刷新前页面
@property (nonatomic, assign) BOOL isNeedPreRefreshPart; // 是否局部刷新前页面

- (instancetype)initWithAddress:(NSString *)address;
- (instancetype)initWithURL:(NSURL *)url;

- (void)loadHTMLString:(NSString *)string;
- (void)loadURL:(NSURL *)url;

@end
