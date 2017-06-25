//
//  WAUserInterfaceAPI.m
//  YYFoundation
//
//  Created by wuwei on 14-5-4.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import "WAUserInterfaceAPI.h"
#import "WAUserInterfaceViewControllerInstantiable.h"
#import "NSDictionary+Safe.h"
#import "UIView+Toast.h"
#import "YYWKWebView.h"

typedef enum : NSUInteger {
    AnimationIdMoMoDa = 1
} AnimationId;

NSString * const WABindPhoneSuccessNotification = @"WABindPhoneSuccessNotification";


@interface WAUserInterfaceAPI () <CAAnimationDelegate>

@property (nonatomic, weak) id<WAUserInterfaceContext> context;
@property (nonatomic, strong) YYWACallback uploadImageBack;
@property (nonatomic, assign) BOOL isCustomBackBtn;   //setNavigationBar里设置的leftItem，是特殊的BackBtn
@property (nonatomic, strong) UIButton *weekTaskBtn; //周任务钻石按钮,引用以实现动画
@property (nonatomic, strong) NSMutableArray *numArray; //周任务钻石按钮数据数组

@property (nonatomic, assign) BOOL overwrite ;

@property (nonatomic, strong) YYWACallback navigationBarItemCallback;

@end

@implementation WAUserInterfaceAPI

@synthesize context = _context;

- (instancetype)initWithContext:(id<WAUserInterfaceContext>)context
{
    self = [super init];
    if (self) {
        _context = context;
    }
    return self;
}

-(id)getContext {
    return _context;
}

- (NSString*)module
{
    return @"ui";
}

#pragma mark - Web API

/*
- (id)toast:(id)parameter callback:(YYWACallback)callback
{
    if ([parameter isKindOfClass:[NSDictionary class]] && [(NSDictionary*)parameter count] > 0) {
        NSString* content = [parameter objectForKey:@"msg"];
        [UIView makeToast:content duration:3 position:ToastPositionCenter];
    }
    
    return nil;
}

- (id)showAlertDialog:(id)parameter callback:(YYWACallback)callback
{
    if ([parameter isKindOfClass:[NSDictionary class]]) {
        NSString* title = [parameter objectForKey:@"title"];
        NSString* message = [parameter objectForKey:@"message"];
        NSArray* buttons = [parameter objectForKey:@"buttons"];
        if (message && buttons.count) {
            AlertView* alertView = [AlertView.alloc initWithTitle:title message:message];
            for (NSUInteger index = 0; index < buttons.count; index++) {
                id button = buttons[index];
                if ([button isKindOfClass:[NSString class]]) {
                    __block YYWACallback cb = callback ? [callback copy] : NULL;
                    [alertView addButton:button clickBlock:^{
                        if (cb) {
                            cb(@{@"index": @(index)});
                        }
                    }];
                }
                else {
                    if (callback) {
                        callback(@{ @"index" : @(-1),
                                    @"error" : @"Error: buttons should be an array of strings." });
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView show];
            });
        }
        else {
            if (callback) {
                callback(@{ @"index" : @(-1),
                            @"error" : @"Error: message and buttons is required." });
            }
        }
    }
    
    return nil;
}

- (id)showThreeButtonDialog:(id)parameter callback:(YYWACallback)callback
{
    return [self showAlertDialog:parameter callback:callback];
}

- (id)closeAllWindow:(id)parameter callback:(YYWACallback)callback
{
    if ([self.context respondsToSelector:@selector(closeAllWindowWithUserInterfaceAPI:)]) {
        [self.context closeAllWindowWithUserInterfaceAPI:self];
    }
    else if ([self.context isKindOfClass:[UIViewController class]]) {
        [((UIViewController*)self.context).navigationController popToRootViewControllerAnimated:YES];
    }
    return nil;
}

- (id)gotoBrowser:(id)parameter callback:(YYWACallback)callback
{
    NSString* uriStr = [parameter stringForKey:@"url"];
    NSURL* uri = [[NSURL alloc] initWithString:uriStr];
    [[UIApplication sharedApplication] openURL:uri];
    return nil;
}

- (id)showBackBtn:(id)parameter callback:(YYWACallback)callback
{
    if (self.isCustomBackBtn){
        self.isCustomBackBtn = NO;
        if ([self.context isKindOfClass:[UIViewController class]]){
            ((UIViewController*)self.context).navigationItem.leftBarButtonItems = nil;
        }
    }
    if ([self.context respondsToSelector:@selector(showBackBtnWithUserInterfaceAPI:)]) {
        [self.context showBackBtnWithUserInterfaceAPI:self];
    }
    else if ([self.context isKindOfClass:[UIViewController class]]) {
        [((UIViewController*)self.context).navigationItem setHidesBackButton:NO];
    }
    return nil;
}

- (id)hideBackBtn:(id)parameter callback:(YYWACallback)callback
{
    if (self.isCustomBackBtn){
        self.isCustomBackBtn = NO;
        if ([self.context isKindOfClass:[UIViewController class]]) {
            ((UIViewController*)self.context).navigationItem.leftBarButtonItems = nil;
        }
    }
    if ([self.context respondsToSelector:@selector(hideBackBtnWithUserInterfaceAPI:)]) {
        [self.context hideBackBtnWithUserInterfaceAPI:self];
    }
    else if ([self.context isKindOfClass:[UIViewController class]]) {
        [((UIViewController*)self.context).navigationItem setHidesBackButton:YES];
    }
    return nil;
}

- (id)setNavigationBar:(id)parameter callback:(YYWACallback)callback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([parameter isKindOfClass:[NSDictionary class]]) {
            NSDictionary* dicTitle = [parameter dictionaryForKey:@"title"];
            NSDictionary* dicLeftItem = [parameter dictionaryForKey:@"leftItem"];
            NSDictionary* dicRightItem = [parameter dictionaryForKey:@"rightItem"];
            
            if (dicTitle != nil){
                NSString *titleText = [dicTitle stringForKey:@"title"];
                if ([self.context isKindOfClass:[UIViewController class]]) {
                    [((UIViewController*)self.context).navigationItem setTitle:titleText];
                }
            }
            
            if (dicLeftItem != nil) {
                NSInteger tagId = [dicLeftItem numberForKey:@"id"].integerValue;
                NSArray *buttonArray = nil;
                NSNumber* numEnabled = [dicLeftItem numberForKey:@"enabled"];   //默认true
                NSNumber* numHidden = [dicLeftItem numberForKey:@"hidden"];     //默认false
                if (!numHidden.boolValue){
                    UIBarButtonItem *negativeSpacerLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
                    [negativeSpacerLeft setWidth:-4];
                    
                    UIBarButtonItem* backBarButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(onNavigationBarLeftItemClicked:)];
                    backBarButton.tag = tagId;
                    if (numEnabled!=nil && numEnabled.boolValue == NO){
                        backBarButton.enabled = false;
                    }
                    buttonArray = [[NSArray alloc]initWithObjects:negativeSpacerLeft, backBarButton, nil];
                }
                
                YYWKWebViewController *controller = ((YYWKWebViewController*)self.context);
                controller.navigationItem.leftBarButtonItems = buttonArray;
                self.isCustomBackBtn = YES;
            }
            
            if (dicRightItem != nil){
                
                NSString *style  = [dicRightItem stringForKey:@"style"];
                NSString *title = [dicRightItem stringForKey:@"title"];
                NSInteger id = [dicRightItem numberForKey:@"id"].integerValue;
                NSString *imgUrl = [dicRightItem stringForKey:@"img"];
                
                NSArray *buttonArray = nil;
                NSNumber* numEnabled = [dicRightItem numberForKey:@"enabled"];
                NSNumber* numHidden = [dicRightItem numberForKey:@"hidden"];     //默认false
                if (!numHidden.boolValue && title != nil && title.length > 0){
                    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:title
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(onNavigationBarRightItemClicked:)];
                    buttonItem.tag = id;
                    if (numEnabled!=nil && numEnabled.boolValue == NO){
                        buttonItem.enabled = false;
                    }
                    buttonArray = [[NSArray alloc]initWithObjects:buttonItem, nil];
                }
                if (!numHidden.boolValue && title != nil && title.length > 0 && imgUrl!=nil && imgUrl.length > 0) {
                    UIButton* moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                    moreBtn.frame = CGRectMake(0, 0, 66, 32);
                    [moreBtn setTitle:title forState:UIControlStateNormal];
                    
                    UIEdgeInsets titleInsets = moreBtn.titleEdgeInsets;
                    titleInsets.left = 3;
                    moreBtn.titleEdgeInsets = titleInsets;
                    UIEdgeInsets imageInsets = moreBtn.imageEdgeInsets;
                    imageInsets.left = -5;
                    moreBtn.imageEdgeInsets = imageInsets;
                    
                    CGFloat titleWidth = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 24) options:0 attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0]} context:nil].size.width;
                    CGRect frame = moreBtn.frame;
                    frame.size.width = titleWidth + 50;
                    moreBtn.frame = frame;
                    
                    [moreBtn addTarget:self action:@selector(onNavigationBarRightItemClicked:) forControlEvents:UIControlEventTouchUpInside];
                    [moreBtn setTitleColor:[UIColor themeColor1] forState:UIControlStateNormal];
                    UIBarButtonItem* moreBarItem = [[UIBarButtonItem alloc] initWithCustomView:moreBtn];
                    moreBarItem.tag = id;
                    __block UIImage *urlImg = [UIImage imageNamed:@"weekTask_shop_dia"];
                    YYWebImageManager *manager = [YYWebImageManager sharedManager];
                    [manager downloadWithURL:[NSURL URLWithString:imgUrl] options:0 progress:nil completed:^(UIImage *image, NSError *error, YYWebImageCacheType cacheType, BOOL finished) {
                        urlImg = image;
                        CGSize imgSize = CGSizeMake(16.0f, 16.0f);
                        urlImg = [urlImg resizedImageWithRestrictSize:imgSize];
                        [moreBtn setImage:urlImg forState:UIControlStateNormal];
                    }];
                    if (numEnabled!=nil && numEnabled.boolValue == NO){
                        moreBarItem.enabled = false;
                        moreBtn.titleLabel.alpha = 0.8;
                    }
                    
                    if ([style isEqualToString:@"task_default"]){
                        
                        self.weekTaskBtn = moreBtn;
                        [self.weekTaskBtn setBackgroundImage:[UIImage imageNamed:@"diamondbtn_bg_normal"] forState:UIControlStateNormal];
                        self.numArray = [NSMutableArray array];
                        
                    }else{
                        self.weekTaskBtn = nil;
                        self.numArray = nil;
                    }
                    buttonArray = [[NSArray alloc]initWithObjects:moreBarItem, nil];
                }
                if ([self.context isKindOfClass:[UIViewController class]]) {
                    ((UIViewController*)self.context).navigationItem.rightBarButtonItems = buttonArray;
                }
            }
            
            if (callback != nil){
                self.navigationBarItemCallback = callback;
            }
        }
        
    });
    return nil;
}

- (id)setTitleWithBackground:(id)parameter callback:(YYWACallback)callback {
    return nil;
}

- (id)setWebViewHeight:(id)parameter callback:(YYWACallback)callback
{
    CGFloat height = [[parameter stringForKeyCompatibleNumber:@"h"] floatValue];
    NSString *actId = [parameter stringForKey:@"actId"];

    if ([self.context respondsToSelector:@selector(updateWebViewHeight:height:)]) {
        [self.context updateWebViewHeight:actId height:height];
    }
    return nil;
}

- (void)onNavigationBarLeftItemClicked:(id)sender
{
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    if (item != nil){
        if (item.tag == 0){
            //id为0不监听返回按钮，直接返回
            [self popViewController:nil callback:nil];
        }
        else if (self.navigationBarItemCallback){
            self.navigationBarItemCallback(@{@"id": @(item.tag)});
        };
    }
}

- (void)onNavigationBarRightItemClicked:(id)sender
{
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    if (item != nil){
        if (self.navigationBarItemCallback){
            self.navigationBarItemCallback(@{@"id": @(item.tag)});
        };
    }
}


- (id)setWebViewWidth:(id)parameter callback:(YYWACallback)callback
{
    CGFloat width = [[parameter stringForKeyCompatibleNumber:@"w"] floatValue];
    NSString *actId = [parameter stringForKey:@"actId"];

    if ([self.context respondsToSelector:@selector(updateWebViewHeight:height:)]) {
        [self.context updateWebViewWidth:actId width:width];
    }
    return nil;
}


- (id)popViewController:(id)parameter callback:(YYWACallback)callback
{
    BOOL shouldPop = NO;
    if ([self.context respondsToSelector:@selector(shouldPopWithUserInterfaceAPI:)]) {
        shouldPop = [self.context shouldPopWithUserInterfaceAPI:self];
    }
    else if ([self.context isKindOfClass:[UIViewController class]]) {
        UIViewController* popedViewController = [((UIViewController*)self.context).navigationController
                                                 popViewControllerAnimated:YES];
        if (popedViewController) {
            shouldPop = YES;
        } else {
            [((UIViewController*)self.context).navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    CALLBACK_AND_RETURN(@(shouldPop));
}

// 蚂蚁金服认证
- (id)zmCerticate:(id)parameter callback:(YYWACallback)callback {
    
    NSDictionary *certifyParams = [NSJSONSerialization JSONObjectWithData:[parameter[@"certifyUrl"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    NSString *appId = certifyParams[@"app_id"]; // @"1001556"
    NSString *sign = certifyParams[@"sign"]; // @"KHKXzZCrVL2cQTDnAJ4LdC+GVNlGsjMDgZbue+ShjwL5XJqNAbYJtkJ6IaifWgkW8vfvNJuhiZJWMUBFLPrBG6DtkRakn61YvZOL31duGLWjUfp2gUxBeErzYOdQLnrjvh+umO/hkB6LNysmmSzaKu9YXC4jXDBe2ZURIcIG6BI="
    NSString *params = certifyParams[@"params"]; // @"XP50pFz4OUz9HNsDx70OdqeeU59xQcHF4hfRet8XSF7N1xHWyucXnaGWi+uUqWHHacZ7qJOYdrdlS6n7fcOjYJXw/GwZyqcPe1dAZK0IUz1kEIxuqPerbPh1kUPGO9TqrqQqShMkDEVF08i2l9c6+paGvs0rPalyfhjSEVwrfqA="
    
    //[[ALCreditService sharedService] setCurrentEnv:@"mock"];
    YYZMSDKHook *hook = [[YYZMSDKHook alloc] init];
    UIViewController *cur = [YYViewControllerCenter currentRootViewControllerInStack];
    if ([cur isKindOfClass:[UITabBarController class]]) {
        UITabBarController *temp1 = (UITabBarController *)cur;
        cur = temp1.selectedViewController;
        if ([cur isKindOfClass:[UINavigationController class]]) {
            UINavigationController *temp2 = (UINavigationController *)cur;
            cur = temp2.topViewController;
        }
    }
    hook.zmEntranceVC = cur;
    
    [[ALCreditService sharedService] setNaviBarColor:[UIColor whiteColor] titleColor:[UIColor blackColor]];
    [[ALCreditService sharedService] certifyUserInfoReq:appId sign:sign params:params target:hook.zmEntranceVC extParams:nil block:^(NSMutableDictionary *resultDic) {
        
        NSString *authResult = [NSString stringWithFormat:@"%@", resultDic[@"authResult"]];
        
        if ([authResult isEqualToString:@"ZMSDK.user_auth_finish"]
            || [authResult isEqualToString:@"ZMCSP.user_auth_finish"]
            || [authResult isEqualToString:@"ZMCSP.user_cancel"]) {
            
            [hook stopHookTimer];
            hook.zmEntranceVC = nil;
            
        }
        
        if ([authResult isEqualToString:@"ZMSDK.user_auth_finish"]
            || [authResult isEqualToString:@"ZMCSP.user_auth_finish"]) {
            
            [hook showyyResultPageWithResultDic:resultDic];
        }
    }];
    CALLBACK_AND_RETURN(nil);
}

- (id)isClientSupportAsynWebView:(id)parameter callback:(YYWACallback)callback {
    CALLBACK_AND_RETURN(@(1));
}

- (id)showLoginDialog:(id)parameter callback:(YYWACallback)callback
{
    
    if ([[AuthSrv sharedInstance] getUserId] == 0) {
        
        [AuthEntryViewController presentEntry:nil];
        if (callback) {
            callback(@{});
        }
    } else {
        [UIView makeToast:@"您当前已经登录了" duration:3 position:ToastPositionCenter];
    }
    return nil;
}

- (id) goto:(id)parameter callback:(YYWACallback)callback
{
    NSString* uri = [parameter stringForKey:@"uri"] ? :@"";
    if (uri.length > 0) {
        if ([self.context respondsToSelector:@selector(userInterfaceAPI:gotoURI:)]) {
            [self.context userInterfaceAPI:self gotoURI:uri];
        }
        else if ([self.context isKindOfClass:[UIViewController class]]) {
            [[URINavigationCenter sharedObject] handleURI:uri
                                       fromViewController:(UIViewController*)self.context
                                                 animated:YES];
        }
    }
    return nil;
}

- (id)setNavigationBarTitle:(id)parameter callback:(YYWACallback)callback
{
    NSString* titleText = [parameter stringForKey:@"title"];
    if ([self.context respondsToSelector:@selector(setNavigationBarTitleWithUserInterfaceAPI:title:)]) {
        [self.context setNavigationBarTitleWithUserInterfaceAPI:self title:titleText];
    }
    else if ([self.context isKindOfClass:[UIViewController class]]) {
        [((UIViewController*)self.context).navigationItem setTitle:titleText];
    }
    return nil;
}

- (id)setPageBackMode:(id)parameter callback:(YYWACallback)callback {
    
    if (self.context && [self.context respondsToSelector:@selector(setPageBackMode:)]) {
        [self.context setPageBackMode:parameter];
    }
    return nil;
}

- (id)screenWidthHeight:(id)parameter callback:(YYWACallback)callback {
    
    NSDictionary *dic = @{@"screenWidthDp":@(SCREEN_WIDTH),
                          @"screenHeightDp":@(SCREEN_HEIGHT)};
    CALLBACK_AND_RETURN(dic);
}

- (void)openActWindow:(id)parameter callback:(YYWACallback)callback  {
    if (self.context && [self.context respondsToSelector:@selector(openActWindow:)]) {
        [self.context openActWindow:parameter];
    } else {
        [YYActivityWindow ShowFrame:[[UIScreen mainScreen] bounds] parameter:parameter hideCall:nil];
    }
}

- (id)closeActWindow:(id)parameter callback:(YYWACallback)callback {
    if (self.context && [self.context respondsToSelector:@selector(closeActWindow)]) {
        [self.context closeActWindow];
    }
    return nil;
}

- (void)onOrderStatusChange:(id)parameter callback:(YYWACallback)callback {
    
    id status = [parameter objectForKey:@"status"];
    if ([status respondsToSelector:@selector(integerValue)]) {
        NSInteger res = [status integerValue];
        if (res == 1 || res == 0) {
            [[PaidManager sharedInstance] hidTipsView];
        }
    } else if ([status isKindOfClass:[NSNumber class]]) {
        NSNumber *temp = status;
        if (temp) {
            if (temp.integerValue == 1 || temp.integerValue == 0) {
                [[PaidManager sharedInstance] hidTipsView];
            }
        }
    }
}

- (void)fillBuyerAddress:(id)parameter callback:(YYWACallback)callback {
    
    AddressListViewController *vc = (AddressListViewController *)[AddressViewControllerFactory addressListViewController];
    if (vc) {
        
        __weak __typeof (self) weakSelf = self;
        vc.onAddressBlock = ^(AddressInfo *address) {

            NSDictionary *dic = @{
                                  @"addressId":address.addressId>0?@(address.addressId).stringValue:@"",
                                  @"name":address.name? : @"",
                                  @"phone":address.phone? : @"",
                                  @"area":address.area? :@"",
                                  @"address":address.address? :@""
                                  };
            callback(dic);
            
            if (nil == address) {
                if ([weakSelf.context respondsToSelector:@selector(reloadWebView)]) {
                    [weakSelf.context reloadWebView];
                }
            }
        };
        YYNavigationController *nav = [[YYNavigationController alloc] initWithRootViewController:vc];
        UIViewController *cur = [YYViewControllerCenter currentRootViewControllerInStack];
        [cur presentViewController:nav animated:YES completion:nil];
    }
}

- (id)setPullRefreshEnable:(id)parameter callback:(YYWACallback)callback {
    
    if (self.context && [self.context respondsToSelector:@selector(setPullRefreshEnable:)]) {
        NSNumber *res = [parameter numberForKey:@"isRefresh"];
        [self.context setPullRefreshEnable:res.boolValue];
    }
    return nil;
}

- (id)showProgressWindow:(id)parameter callback:(YYWACallback)callback {
    
    BOOL isShow = [parameter boolForKey:@"show"];
    NSInteger timeout = [parameter integerForKey:@"timeout"];
    if (self.context && [self.context respondsToSelector:@selector(loadingAnimation:timeout:)]) {
        [self.context loadingAnimation:isShow timeout:timeout];
    }
    CALLBACK_AND_RETURN(nil);
}

#define OpenCameraOrAlbumCommon_Result_JS(type, json) [NSString stringWithFormat:@"window.unifiedResultToWeb(%d, '%@');", type, json]

- (id)openCameraOrAlbumForUrl:(id)parameter callback:(YYWACallback)callback
{
    if (![parameter isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    self.uploadImageBack = callback;
    YYLiveAlbumSelectController *albumCtrl = [[YYLiveAlbumSelectController alloc] init];
    albumCtrl.delegate = self;
    YYLiveCoverSelectController *coverCtrl = [[YYLiveCoverSelectController alloc] init];
    coverCtrl.delegate = self;
    NSArray *vcs = @[albumCtrl, coverCtrl];
    
    YYNavigationController *navCtrl = [[YYNavigationController alloc] init];
    [navCtrl setViewControllers:vcs];
    
    [[YYViewControllerCenter currentRootViewControllerInStack] presentViewController:navCtrl animated:YES completion:nil];
    return (nil);
}

- (id)openCameraOrAlbumCommon:(id)parameter callback:(YYWACallback)callback
{
    if (![parameter isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    YYLiveAlbumSelectController *albumCtrl = [[YYLiveAlbumSelectController alloc] init];
    albumCtrl.delegate = self;
    YYLiveCoverSelectController *coverCtrl = [[YYLiveCoverSelectController alloc] init];
    coverCtrl.delegate = self;
    NSArray *vcs = @[albumCtrl, coverCtrl];
    
    YYNavigationController *navCtrl = [[YYNavigationController alloc] init];
    [navCtrl setViewControllers:vcs];
    
    [[YYViewControllerCenter currentRootViewControllerInStack] presentViewController:navCtrl animated:YES completion:nil];
    CALLBACK_AND_RETURN(nil);
}

- (void)onTakePhoto
{
    if (!self.takePhotoModel) {
        _takePhotoModel = [[YYTakePhotoModel alloc] init];
        _takePhotoModel.originalImageAllowed = YES;
    }

    __weak typeof(self)weakSelf = self;
    [self.takePhotoModel showCameraWithUsingCameraBlock:^(BOOL isUsingCamera) {
        if (isUsingCamera) {
            
        }
    } Completion:^(UIImage *pickingImage) {
        
        if (pickingImage) {
            
            if (weakSelf.uploadImageBack) {
                [weakSelf uploadImage:pickingImage];
                return ;
            }
            NSMutableDictionary *returnJSON = [NSMutableDictionary dictionary];
            NSString *key = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
            NSString *json = [UIImageJPEGRepresentation(pickingImage, 0.2) base64EncodedStringWithOptions: NSDataBase64EncodingEndLineWithCarriageReturn];
            NSArray *array = @[@{ @"thumbnail" : json, @"localFileName" : key?key:@""}];
            returnJSON[@"code"] = @1;
            returnJSON[@"message"] = @"";
            returnJSON[@"data"] = array;
            [weakSelf dispatchOpenCameraOrAlbumJS:OpenCameraOrAlbumCommon_Result_JS(2,[returnJSON yy_JSONString])];
            
            [[YYViewControllerCenter currentRootViewControllerInStack] dismissViewControllerAnimated:NO completion:nil];
        }
    }];
}

- (void)onSelectPhoto:(UIImage *)originImage
{
    
    if (!self.takePhotoModel) {
        _takePhotoModel = [[YYTakePhotoModel alloc] init];
        _takePhotoModel.originalImageAllowed = YES;
    }
    __weak typeof(self)weakSelf = self;
    [self.takePhotoModel selectPhotoWithImage:originImage fromCamera:NO completion:^(UIImage *pickingImage) {
        if (pickingImage) {
            
            if (weakSelf.uploadImageBack) {
                [weakSelf uploadImage:pickingImage];
                return ;
            }
            NSMutableDictionary *returnJSON = [NSMutableDictionary dictionary];
            NSString *key = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
            NSString *json = [UIImageJPEGRepresentation(pickingImage, 0.2) base64EncodedStringWithOptions: NSDataBase64EncodingEndLineWithCarriageReturn];
            NSArray *array = @[@{ @"thumbnail" : json, @"localFileName" : key?key:@""}];
            returnJSON[@"code"] = @1;
            returnJSON[@"message"] = @"";
            returnJSON[@"data"] = array;
            [weakSelf dispatchOpenCameraOrAlbumJS:OpenCameraOrAlbumCommon_Result_JS(2,[returnJSON yy_JSONString])];
        }
        [[YYViewControllerCenter currentRootViewControllerInStack] dismissViewControllerAnimated:NO completion:^{
        }];
    }];
}

- (void)uploadImage:(UIImage *)image {
    
    __weak __typeof (self) weakSelf = self;
    NSString *fileName = [NSString stringWithFormat:@"%lld_%f.jpg", [[AuthSrv sharedInstance] getUserId], [[NSDate date] timeIntervalSince1970]];
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [MBProgressHUD showHUDAddedTo:window animated:YES];

    [[BS2Srv sharedInstance] upload:image fileName:fileName onCompletion:^(BOOL isSuccess, NSString * _Nullable coverUrl) {
        
        if (isSuccess) {
            NSMutableDictionary *returnJSON = [NSMutableDictionary dictionary];
            NSArray *array = @[coverUrl];
            returnJSON[@"code"] = @1;
            returnJSON[@"message"] = @"";
            returnJSON[@"data"] = array;
            
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            MBProgressHUD *hud =[MBProgressHUD HUDForView:window];
            [hud hideAnimated:YES];
            
            [[YYViewControllerCenter currentRootViewControllerInStack] dismissViewControllerAnimated:NO completion:nil];
            if (weakSelf.uploadImageBack) {
                weakSelf.uploadImageBack(returnJSON);
                weakSelf.uploadImageBack = nil;
            }
        }
    }];
}

- (void)dispatchOpenCameraOrAlbumJS:(NSString *)javaScript
{
    
    if (self.context && [self.context respondsToSelector:@selector(onCallBackJavaScript:)]) {
        [self.context onCallBackJavaScript:javaScript];
    }
}

- (id)scanQRCode:(id)parameter callback:(YYWACallback)callback {
    
    NSString *title = [parameter objectForKey:@"title"] ? : @"";
    QRViewController *qr = [[QRViewController alloc] init];
    qr.title = title;
    qr.scanRes = ^(NSString *code) {
        callback(code);
    };
    [[YYViewControllerCenter currentRootViewControllerInStack] safePushViewController:qr animated:YES];
    return nil;
}
*/

@end

@implementation WAUserInterfaceURIAuthorityEntity

@end

