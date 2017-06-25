//
//  YYLoadingToastView.m
//  YYMobile
//
//  Created by 武帮民 on 14-8-13.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import "YYLoadingToastView.h"
#import "SafeTimer.h"
#import "YYViewControllerCenter.h"

const NSInteger interval = 1.5f;

@interface YYLoadingToastView ()

@property (nonatomic, strong) SafeTimer *timer;
@property (nonatomic, strong) UIView * animationView;

@property (nonatomic, strong) NSString *loadingMsg;

@end

@implementation YYLoadingToastView

+ (instancetype)instantiateLoadingToast {
    YYLoadingToastView *view = [[YYLoadingToastView alloc] initWithLoadingView:nil];
    
    return view;
}

+ (instancetype)instantiateLoadingToastWithText:(NSString *)msg {
    YYLoadingToastView *view = [[YYLoadingToastView alloc] initWithLoadingView:msg];
    
    return view;
}

- (instancetype)initWithLoadingView:(NSString *)msg {
    self = [super init];
    
    if (self) {
        
        self.loadingMsg = msg;
        
        [self loadLoadingView];
        //[self animationWithView:self.animationView];
        //_timer = [SafeTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timerFireMethod) repeats:YES];
    }
    
    return self;
}

- (void)loadLoadingView {
    
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.backgroundColor = [UIColor clearColor];
    
    UIImageView *circleImag = [[UIImageView alloc] init];
    [self addImageAnimation:circleImag];
    [circleImag sizeToFit];
    wrapperView.frame = CGRectMake(0.0, 0.0, 200, 200);
    
    CGPoint viewCenter = wrapperView.center;
    
    circleImag.center = viewCenter;
    
    [wrapperView addSubview:circleImag];
    
    if (self.loadingMsg && self.loadingMsg.length) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.text = self.loadingMsg;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13];
        label.frame = CGRectMake(0, viewCenter.y + 20, 200, 20);
        [wrapperView addSubview:label];
    }
    
    self.animationView = circleImag;
    
    self.frame = wrapperView.frame;
    wrapperView.frame = self.bounds;
    
    [self addSubview:wrapperView];
}

- (void)addImageAnimation:(UIImageView *)imageView {
    
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:17];
    for (int i = 4; i <= 21; i++) {
        NSString *imageString = [NSString stringWithFormat:@"loading_%05d", i];
        UIImage *image = [UIImage imageNamed:imageString];
        if (image) {
            [arr addObject:image];
        }
    }
    imageView.animationImages = [arr copy];
    imageView.animationDuration = 18. / 15;
    [imageView startAnimating];
}

- (void)animationWithView:(UIView *)view {
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = interval;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1;
    
    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
}

- (void)timerFireMethod {
    
    if (self.superview == nil) {
        [self.timer invalidate];
    } else {
        [self animationWithView:self.animationView];
    }
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
    _timer = nil;
}

@end
