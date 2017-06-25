//
//  UIView+Toast.m
//  Toast
//
//  Copyright (c) 2011-2016 Charles Scalesse.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "UIView+Toast.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "UIColor+ColorUtil.h"

NSString * ToastPositionTop                       = @"ToastPositionTop";
NSString * ToastPositionCenter                    = @"ToastPositionCenter";
NSString * ToastPositionKeyboardAbove             = @"ToastPositionKeyboardAbove";
NSString * ToastPositionTabbarAbove               = @"ToastPositionTabbarAbove";
NSString * ToastPositionBottom                    = @"ToastPositionBottom";

// Keys for values associated with toast views
static const NSString * ToastTimerKey             = @"ToastTimerKey";
static const NSString * ToastDurationKey          = @"ToastDurationKey";
static const NSString * ToastPositionKey          = @"ToastPositionKey";
static const NSString * ToastCompletionKey        = @"ToastCompletionKey";

// Keys for values associated with self
static const NSString * ToastActiveKey            = @"ToastActiveKey";
static const NSString * ToastActivityViewKey      = @"ToastActivityViewKey";
static const NSString * ToastQueueKey             = @"ToastQueueKey";

@interface UIView (ToastPrivate)

/**
 These private methods are being prefixed with "p_" to reduce the likelihood of non-obvious 
 naming conflicts with other UIView methods.
 
 @discussion Should the public API also use the p_ prefix? Technically it should, but it
 results in code that is less legible. The current public method names seem unlikely to cause
 conflicts so I think we should favor the cleaner API for now.
 */
- (void)p_showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)position;
- (void)p_hideToast:(UIView *)toast;
- (void)p_hideToast:(UIView *)toast fromTap:(BOOL)fromTap;
- (void)p_toastTimerDidFinish:(NSTimer *)timer;
- (void)p_handleToastTapped:(UITapGestureRecognizer *)recognizer;
- (CGPoint)p_centerPointForPosition:(id)position withToast:(UIView *)toast;
- (NSMutableArray *)p_toastQueue;

@end

@implementation UIView (Toast)

#pragma mark - Make Toast Methods

+ (void)makeToast:(NSString *)message {
    [[ToastManager defaultWindow] makeToast:message];
}

- (void)makeToast:(NSString *)message {
    [self makeToast:message duration:[ToastManager defaultDuration] position:[ToastManager defaultPosition] style:nil];
}

+ (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position {
    [[ToastManager defaultWindow] makeToast:message duration:duration position:position];
}

- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position {
    [self makeToast:message duration:duration position:position style:nil];
}

+ (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position style:(ToastStyle *)style {
    [[ToastManager defaultWindow] makeToast:message duration:duration position:position style:style];
}

- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position style:(ToastStyle *)style {
    UIView *toast = [self toastViewForMessage:message title:nil image:nil style:style];
    [self showToast:toast duration:duration position:position completion:nil];
}

+ (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position title:(NSString *)title image:(UIImage *)image style:(ToastStyle *)style completion:(void(^)(BOOL didTap))completion {
    [[ToastManager defaultWindow] makeToast:message duration:duration position:position title:title image:image style:style completion:completion];
}

     
- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position title:(NSString *)title image:(UIImage *)image style:(ToastStyle *)style completion:(void(^)(BOOL didTap))completion {
    UIView *toast = [self toastViewForMessage:message title:title image:image style:style];
    [self showToast:toast duration:duration position:position completion:completion];
}

#pragma mark - Show Toast Methods

- (void)showToast:(UIView *)toast {
    [self showToast:toast duration:[ToastManager defaultDuration] position:[ToastManager defaultPosition] completion:nil];
}

- (void)showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)position completion:(void(^)(BOOL didTap))completion {
    // sanity
    if (toast == nil) return;
    
    // store the completion block on the toast view
    objc_setAssociatedObject(toast, &ToastCompletionKey, completion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([ToastManager isQueueEnabled] && [self.p_activeToasts count] > 0) {
        // we're about to queue this toast view so we need to store the duration and position as well
        objc_setAssociatedObject(toast, &ToastDurationKey, @(duration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(toast, &ToastPositionKey, position, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // enqueue
        [self.p_toastQueue addObject:toast];
    } else {
        // present
        [self p_showToast:toast duration:duration position:position];
    }
}

#pragma mark - Hide Toast Method

- (void)hideToasts {
    for (UIView *toast in [self p_activeToasts]) {
        [self hideToast:toast];
    }
}

+ (void)hideToasts
{
    [[ToastManager defaultWindow] hideToasts];
}

- (void)hideToast:(UIView *)toast {
    // sanity
    if (!toast || ![[self p_activeToasts] containsObject:toast]) return;
    
    NSTimer *timer = (NSTimer *)objc_getAssociatedObject(toast, &ToastTimerKey);
    [timer invalidate];
    
    [self p_hideToast:toast];
}

+ (void)hideToast:(UIView *)toast {
    [[ToastManager defaultWindow] hideToast:toast];
}


#pragma mark - Private Show/Hide Methods

- (void)p_showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)position {
    toast.center = [self p_centerPointForPosition:position withToast:toast];
    toast.alpha = 0.0;
    
    if ([ToastManager isTapToDismissEnabled]) {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleToastTapped:)];
        [toast addGestureRecognizer:recognizer];
        toast.userInteractionEnabled = YES;
        toast.exclusiveTouch = YES;
    }
    
    [[self p_activeToasts] addObject:toast];
    
    [self addSubview:toast];
    
    [UIView animateWithDuration:[[ToastManager sharedStyle] fadeDuration]
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         toast.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         NSTimer *timer = [NSTimer timerWithTimeInterval:duration target:self selector:@selector(p_toastTimerDidFinish:) userInfo:toast repeats:NO];
                         [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
                         objc_setAssociatedObject(toast, &ToastTimerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                     }];
}

- (void)p_hideToast:(UIView *)toast {
    [self p_hideToast:toast fromTap:NO];
}
    
- (void)p_hideToast:(UIView *)toast fromTap:(BOOL)fromTap {
    [UIView animateWithDuration:[[ToastManager sharedStyle] fadeDuration]
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         toast.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [toast removeFromSuperview];
                         
                         // remove
                         [[self p_activeToasts] removeObject:toast];
                         
                         // execute the completion block, if necessary
                         void (^completion)(BOOL didTap) = objc_getAssociatedObject(toast, &ToastCompletionKey);
                         if (completion) {
                             completion(fromTap);
                         }
                         
                         if ([self.p_toastQueue count] > 0) {
                             // dequeue
                             UIView *nextToast = [[self p_toastQueue] firstObject];
                             [[self p_toastQueue] removeObjectAtIndex:0];
                             
                             // present the next toast
                             NSTimeInterval duration = [objc_getAssociatedObject(nextToast, &ToastDurationKey) doubleValue];
                             id position = objc_getAssociatedObject(nextToast, &ToastPositionKey);
                             [self p_showToast:nextToast duration:duration position:position];
                         }
                     }];
}

#pragma mark - View Construction

- (UIView *)toastViewForMessage:(NSString *)message title:(NSString *)title image:(UIImage *)image style:(ToastStyle *)style {
    // sanity
    if(message == nil && title == nil && image == nil) return nil;
    
    // default to the shared style
    if (style == nil) {
        style = [ToastManager sharedStyle];
    }
    
    // dynamically build a toast view with any combination of message, title, & image
    UILabel *messageLabel = nil;
    UILabel *titleLabel = nil;
    UIImageView *imageView = nil;
    
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    wrapperView.layer.cornerRadius = style.cornerRadius;
    
    if (style.displayShadow) {
        wrapperView.layer.shadowColor = style.shadowColor.CGColor;
        wrapperView.layer.shadowOpacity = style.shadowOpacity;
        wrapperView.layer.shadowRadius = style.shadowRadius;
        wrapperView.layer.shadowOffset = style.shadowOffset;
    }
    
    wrapperView.backgroundColor = style.backgroundColor;
    
    if(image != nil) {
        imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = CGRectMake(style.horizontalPadding, style.verticalPadding, style.imageSize.width, style.imageSize.height);
    }
    
    CGRect imageRect = CGRectZero;
    
    if(imageView != nil) {
        imageRect.origin.x = style.horizontalPadding;
        imageRect.origin.y = style.verticalPadding;
        imageRect.size.width = imageView.bounds.size.width;
        imageRect.size.height = imageView.bounds.size.height;
    }
    
    if (title != nil) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.numberOfLines = style.titleNumberOfLines;
        titleLabel.font = style.titleFont;
        titleLabel.textAlignment = style.titleAlignment;
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        titleLabel.textColor = style.titleColor;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.alpha = 1.0;
        titleLabel.text = title;
        
        // size the title label according to the length of the text
        CGSize maxSizeTitle = CGSizeMake((self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, self.bounds.size.height * style.maxHeightPercentage);
        CGSize expectedSizeTitle = [titleLabel sizeThatFits:maxSizeTitle];
        // UILabel can return a size larger than the max size when the number of lines is 1
        expectedSizeTitle = CGSizeMake(MIN(maxSizeTitle.width, expectedSizeTitle.width), MIN(maxSizeTitle.height, expectedSizeTitle.height));
        titleLabel.frame = CGRectMake(0.0, 0.0, expectedSizeTitle.width, expectedSizeTitle.height);
    }
    
    if (message != nil) {
        messageLabel = [[UILabel alloc] init];
        messageLabel.numberOfLines = style.messageNumberOfLines;
        messageLabel.font = style.messageFont;
        messageLabel.textAlignment = style.messageAlignment;
        messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        messageLabel.textColor = style.messageColor;
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.alpha = 1.0;
        messageLabel.text = message;
        
        CGSize maxSizeMessage = CGSizeMake((self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, self.bounds.size.height * style.maxHeightPercentage);
        CGSize expectedSizeMessage = [messageLabel sizeThatFits:maxSizeMessage];
        // UILabel can return a size larger than the max size when the number of lines is 1
        expectedSizeMessage = CGSizeMake(MIN(maxSizeMessage.width, expectedSizeMessage.width), MIN(maxSizeMessage.height, expectedSizeMessage.height));
        messageLabel.frame = CGRectMake(0.0, 0.0, expectedSizeMessage.width, expectedSizeMessage.height);
    }
    
    CGRect titleRect = CGRectZero;
    
    if(titleLabel != nil) {
        titleRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding;
        titleRect.origin.y = style.verticalPadding;
        titleRect.size.width = titleLabel.bounds.size.width;
        titleRect.size.height = titleLabel.bounds.size.height;
    }
    
    CGRect messageRect = CGRectZero;
    
    if(messageLabel != nil) {
        messageRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding;
        messageRect.origin.y = titleRect.origin.y + titleRect.size.height + style.verticalPadding;
        messageRect.size.width = messageLabel.bounds.size.width;
        messageRect.size.height = messageLabel.bounds.size.height;
    }
    
    CGFloat longerWidth = MAX(titleRect.size.width, messageRect.size.width);
    CGFloat longerX = MAX(titleRect.origin.x, messageRect.origin.x);
    
    // Wrapper width uses the longerWidth or the image width, whatever is larger. Same logic applies to the wrapper height.
    CGFloat wrapperWidth = MAX((imageRect.size.width + (style.horizontalPadding * 2.0)), (longerX + longerWidth + style.horizontalPadding));
    CGFloat wrapperHeight = MAX((messageRect.origin.y + messageRect.size.height + style.verticalPadding), (imageRect.size.height + (style.verticalPadding * 2.0)));
    
    wrapperView.frame = CGRectMake(0.0, 0.0, wrapperWidth, wrapperHeight);
    
    if(titleLabel != nil) {
        titleLabel.frame = titleRect;
        [wrapperView addSubview:titleLabel];
    }
    
    if(messageLabel != nil) {
        messageLabel.frame = messageRect;
        [wrapperView addSubview:messageLabel];
    }
    
    if(imageView != nil) {
        [wrapperView addSubview:imageView];
    }
    
    return wrapperView;
}

#pragma mark - Storage

- (NSMutableArray *)p_activeToasts {
    NSMutableArray *p_activeToasts = objc_getAssociatedObject(self, &ToastActiveKey);
    if (p_activeToasts == nil) {
        p_activeToasts = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, &ToastActiveKey, p_activeToasts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return p_activeToasts;
}

- (NSMutableArray *)p_toastQueue {
    NSMutableArray *p_toastQueue = objc_getAssociatedObject(self, &ToastQueueKey);
    if (p_toastQueue == nil) {
        p_toastQueue = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, &ToastQueueKey, p_toastQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return p_toastQueue;
}

#pragma mark - Events

- (void)p_toastTimerDidFinish:(NSTimer *)timer {
    [self p_hideToast:(UIView *)timer.userInfo];
}

- (void)p_handleToastTapped:(UITapGestureRecognizer *)recognizer {
    UIView *toast = recognizer.view;
    NSTimer *timer = (NSTimer *)objc_getAssociatedObject(toast, &ToastTimerKey);
    [timer invalidate];
    
    [self p_hideToast:toast fromTap:YES];
}

#pragma mark - Activity Methods

- (void)makeToastActivity:(id)position {
    // sanity
    UIView *existingActivityView = (UIView *)objc_getAssociatedObject(self, &ToastActivityViewKey);
    if (existingActivityView != nil) return;
    
    ToastStyle *style = [ToastManager sharedStyle];
    
    UIView *activityView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, style.activitySize.width, style.activitySize.height)];
    activityView.center = [self p_centerPointForPosition:position withToast:activityView];
    activityView.backgroundColor = style.backgroundColor;
    activityView.alpha = 0.0;
    activityView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    activityView.layer.cornerRadius = style.cornerRadius;
    
    if (style.displayShadow) {
        activityView.layer.shadowColor = style.shadowColor.CGColor;
        activityView.layer.shadowOpacity = style.shadowOpacity;
        activityView.layer.shadowRadius = style.shadowRadius;
        activityView.layer.shadowOffset = style.shadowOffset;
    }
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.center = CGPointMake(activityView.bounds.size.width / 2, activityView.bounds.size.height / 2);
    [activityView addSubview:activityIndicatorView];
    [activityIndicatorView startAnimating];
    
    // associate the activity view with self
    objc_setAssociatedObject (self, &ToastActivityViewKey, activityView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self addSubview:activityView];
    
    [UIView animateWithDuration:style.fadeDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         activityView.alpha = 1.0;
                     } completion:nil];
}

- (void)hideToastActivity {
    UIView *existingActivityView = (UIView *)objc_getAssociatedObject(self, &ToastActivityViewKey);
    if (existingActivityView != nil) {
        [UIView animateWithDuration:[[ToastManager sharedStyle] fadeDuration]
                              delay:0.0
                            options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             existingActivityView.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             [existingActivityView removeFromSuperview];
                             objc_setAssociatedObject (self, &ToastActivityViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                         }];
    }
}

#pragma mark - Helpers

- (CGPoint)p_centerPointForPosition:(id)point withToast:(UIView *)toast {
    ToastStyle *style = [ToastManager sharedStyle];
    
    if([point isKindOfClass:[NSString class]]) {
        if([point caseInsensitiveCompare:ToastPositionBottom] == NSOrderedSame) {
            // default
        } else if([point caseInsensitiveCompare:ToastPositionKeyboardAbove] == NSOrderedSame) {
                return CGPointMake(self.bounds.size.width/2, (self.bounds.size.height - 252 - (toast.frame.size.height / 2)) - style.verticalPadding);
        } else if([point caseInsensitiveCompare:ToastPositionTabbarAbove] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (self.bounds.size.height - 64 - (toast.frame.size.height / 2)) - style.verticalPadding);
        } else if([point caseInsensitiveCompare:ToastPositionCenter] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        }  else if([point caseInsensitiveCompare:ToastPositionTop] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (toast.frame.size.height / 2) + style.verticalPadding);
        }
    } else if ([point isKindOfClass:[NSValue class]]) {
        return [point CGPointValue];
    }
    
    // default to bottom
    return CGPointMake(self.bounds.size.width/2, (self.bounds.size.height - (toast.frame.size.height / 2)) - style.verticalPadding);
}

@end

@implementation ToastStyle

#pragma mark - Constructors

- (instancetype)initWithDefaultStyle {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithR:0x30 G:0x30 B:0x30 alpha:0.9];;
        self.titleColor = [UIColor colorWithRGB:0xffffff];
        self.messageColor = [UIColor colorWithRGB:0xffffff];
        self.maxWidthPercentage = 0.8;
        self.maxHeightPercentage = 0.8;
        self.horizontalPadding = 20.0;
        self.verticalPadding = 10.0;
        self.cornerRadius = 6.0;
        self.titleFont = [UIFont boldSystemFontOfSize:15.0];
        self.messageFont = [UIFont systemFontOfSize:15.0];
        self.titleAlignment = NSTextAlignmentLeft;
        self.messageAlignment = NSTextAlignmentLeft;
        self.titleNumberOfLines = 0;
        self.messageNumberOfLines = 0;
        self.displayShadow = NO;
        self.shadowOpacity = 0.8;
        self.shadowRadius = 6.0;
        self.shadowOffset = CGSizeMake(4.0, 4.0);
        self.imageSize = CGSizeMake(80.0, 80.0);
        self.activitySize = CGSizeMake(100.0, 100.0);
        self.fadeDuration = 0.2;
    }
    return self;
}

- (void)setMaxWidthPercentage:(CGFloat)maxWidthPercentage {
    _maxWidthPercentage = MAX(MIN(maxWidthPercentage, 1.0), 0.0);
}

- (void)setMaxHeightPercentage:(CGFloat)maxHeightPercentage {
    _maxHeightPercentage = MAX(MIN(maxHeightPercentage, 1.0), 0.0);
}

- (instancetype)init NS_UNAVAILABLE {
    return nil;
}

@end

@interface ToastManager ()

@property (strong, nonatomic) ToastStyle *sharedStyle;
@property (assign, nonatomic, getter=isTapToDismissEnabled) BOOL tapToDismissEnabled;
@property (assign, nonatomic, getter=isQueueEnabled) BOOL queueEnabled;
@property (assign, nonatomic) NSTimeInterval defaultDuration;
@property (strong, nonatomic) id defaultPosition;

@end

@implementation ToastManager

#pragma mark - Constructors

+ (instancetype)sharedManager {
    static ToastManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sharedStyle = [[ToastStyle alloc] initWithDefaultStyle];
        self.tapToDismissEnabled = NO;
        self.queueEnabled = YES;
        self.defaultDuration = 3.0;
        self.defaultPosition = ToastPositionBottom;
    }
    return self;
}

#pragma mark - Singleton Methods

+ (void)setSharedStyle:(ToastStyle *)sharedStyle {
    [[self sharedManager] setSharedStyle:sharedStyle];
}

+ (ToastStyle *)sharedStyle {
    return [[self sharedManager] sharedStyle];
}

+ (void)setTapToDismissEnabled:(BOOL)tapToDismissEnabled {
    [[self sharedManager] setTapToDismissEnabled:tapToDismissEnabled];
}

+ (BOOL)isTapToDismissEnabled {
    return [[self sharedManager] isTapToDismissEnabled];
}

+ (void)setQueueEnabled:(BOOL)queueEnabled {
    [[self sharedManager] setQueueEnabled:queueEnabled];
}

+ (BOOL)isQueueEnabled {
    return [[self sharedManager] isQueueEnabled];
}

+ (void)setDefaultDuration:(NSTimeInterval)duration {
    [[self sharedManager] setDefaultDuration:duration];
}

+ (NSTimeInterval)defaultDuration {
    return [[self sharedManager] defaultDuration];
}

+ (UIView*)defaultWindow {
    return [UIApplication sharedApplication].keyWindow;
}

+ (void)setDefaultPosition:(id)position {
    if ([position isKindOfClass:[NSString class]] || [position isKindOfClass:[NSValue class]]) {
        [[self sharedManager] setDefaultPosition:position];
    }
}

+ (id)defaultPosition {
    return [[self sharedManager] defaultPosition];
}

@end
