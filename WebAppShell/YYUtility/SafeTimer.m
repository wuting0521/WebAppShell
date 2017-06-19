//
//  SafeTimer.m
//  OnePiece
//
//  Created by huangshuqing on 17/4/2017.
//  Copyright © 2017 YY. All rights reserved.
//

#import "SafeTimer.h"

@interface SafeTimerImpl : NSObject


@end

@implementation SafeTimerImpl
{
    NSTimer*            _timer;
    dispatch_block_t    _onTimerBlock;
    BOOL                _repeat;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timer = nil;
        _onTimerBlock = nil;
        _repeat = NO;
    }
    return self;
}

-(void)dealloc
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _onTimerBlock = nil;
}

- (void)startTimerWithTimeInterval:(NSTimeInterval)ti block:(dispatch_block_t)aBlock repeats:(BOOL)yesOrNo
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _onTimerBlock = nil;
    
    if (!aBlock) {
        return;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(_timerFireMethod:) userInfo:nil repeats:yesOrNo];
    _onTimerBlock = [aBlock copy];
    _repeat = yesOrNo;
    
}

- (void)invalidate
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _onTimerBlock = nil;
}

- (BOOL)isValid
{
    return (_onTimerBlock != nil && _timer && [_timer isValid]);
}

- (void)addTimerForRunLoopMode:(NSRunLoopMode)mode
{
    if ([self isValid]) {
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:mode];
    }
}

- (void)_timerFireMethod:(NSTimer *)theTimer
{
    if (_onTimerBlock) {
        dispatch_block_t blockCpy = [_onTimerBlock copy];
        if (!_repeat) {
            _onTimerBlock = nil;
        }
        if (blockCpy) {
            blockCpy();
        }
    }
}

@end

@interface SafeTimer ()
@property (nonatomic) SafeTimerImpl* timerImpl;
@end

@implementation SafeTimer

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.timerImpl = nil;
    }
    return self;
}

- (void)dealloc
{
    if (self.timerImpl) {
        [self.timerImpl invalidate];
        self.timerImpl = nil;
    }
}

+ (SafeTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector repeats:(BOOL)yesOrNo
{
    if (aTarget && aSelector && [aTarget respondsToSelector:aSelector]) {
        __typeof(self) __weak weakTarget = aTarget;
        return [self scheduledTimerWithTimeInterval:ti block:[^{
            __typeof(weakTarget) __strong strongTarget = weakTarget;
            if (strongTarget && aSelector && [strongTarget respondsToSelector:aSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [strongTarget performSelector:aSelector];
#pragma clang diagnostic pop
            }
        } copy] repeats:yesOrNo];
    }
    return nil;
}

+ (SafeTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(dispatch_block_t)aBlock repeats:(BOOL)yesOrNo
{
    if (!aBlock) {
        return nil;
    }
    
    SafeTimer* timer = [[SafeTimer alloc] init];
    if (timer) {
        SafeTimerImpl* timerImpl = [[SafeTimerImpl alloc] init];
        if (timerImpl) {
            [timerImpl startTimerWithTimeInterval:ti block:aBlock repeats:yesOrNo];
            timer.timerImpl = timerImpl;
            
            return timer;
        }
    }
    
    return nil;
}

- (void)invalidate
{
    if (_timerImpl) {
        [_timerImpl invalidate];
        _timerImpl = nil;
    }
}

- (BOOL)isValid
{
    return (_timerImpl != nil && [_timerImpl isValid]);
}

- (void)addTimerForRunLoopMode:(NSRunLoopMode)mode
{
    if (_timerImpl) {
        [_timerImpl addTimerForRunLoopMode:mode];
    }
}

@end
