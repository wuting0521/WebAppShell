//
//  YYViewController.m
//  YYMobile
//
//  Created by wuwei on 14/6/11.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import "YYViewController.h"
#import "UIViewController+YYViewControllers.h"

#define YYLoggerTag TControllers

@interface YYViewController () <UIGestureRecognizerDelegate>
{
@private
    
    UITapGestureRecognizer *_tapGestureRecognizer;
}

@property(nullable,nonatomic,weak) id <UIGestureRecognizerDelegate> popDelegate; // the gesture recognizer's delegate


@end

@implementation YYViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

- (void)viewDidLoad
{
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self yy_viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
    
    [super viewWillAppear:animated];
    
    [self registerForKeyboardNotifications];
}

- (void)viewDidAppear:(BOOL)animated
{
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
    
    [super viewDidAppear:animated];
    
    if (self.navigationController.viewControllers.count > 1) { // 记录系统返回手势的代理
        _popDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    [self yy_viewDidAppear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
    
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = _popDelegate;
    
    [self yy_viewWillDisappear];
    
    [self removeKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
    
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [self yy_dealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIGesturePoPRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if (self.navigationController.childViewControllers.count > 1) {
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - UIStyle Prefer
- (UIStatusBarStyle)preferredStatusBarStyle {
    
    return UIStatusBarStyleDefault;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIImage *)preferredNavigationBarBackgroundImageForBarMetrics:(UIBarMetrics)barMetrics
{
    return [UIImage new];
}

- (UIColor *)preferredNavigationBarBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIImage *)preferredNavigationBarShadowImage
{
    return [UIImage new];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations NS_AVAILABLE_IOS(6_0)
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation NS_AVAILABLE_IOS(6_0)
{
    return UIInterfaceOrientationPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


#pragma mark - KeyBroad
- (void)registerForKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)removeKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [self onKeyBroadDidShow:kbSize];
    
    [self addKeyBroadTapBackViewAction];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self onKeyBroadWillHide];
}

- (void)keyboardChangeFrame:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGSize _kbSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    //_keyboardHeight = _kbSize.width > _kbSize.height ? _kbSize.height : _kbSize.width;//考虑横竖屏幕
    
    [self onKeyBroadSizeChanged:_kbSize];
}


- (void)addKeyBroadTapBackViewAction {
    
    if (![self touchViewToHideKeyBroad]) {
        return ;
    }
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(makeKeyboardHide:)];
        // _tapGestureRecognizer.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:_tapGestureRecognizer];
    }
}

- (void)makeKeyboardHide:(id)sender {
    
    if (_tapGestureRecognizer) {
        [self.view removeGestureRecognizer:_tapGestureRecognizer];
        _tapGestureRecognizer = nil;
    }
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

- (BOOL)touchViewToHideKeyBroad {
    
    return YES;
}

// 键盘回调
- (void)onKeyBroadDidShow:(CGSize)kbSize {
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
}

- (void)onKeyBroadSizeChanged:(CGSize)kbSize {
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
}

- (void)onKeyBroadWillHide {
    [YYLogger info:YYLoggerTag message:@"%@ %s", NSStringFromClass([self class]), __FUNCTION__];
}

@end
