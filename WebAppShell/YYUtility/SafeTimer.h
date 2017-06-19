//
//  SafeTimer.h
//  OnePiece
//
//  Created by huangshuqing on 17/4/2017.
//  Copyright © 2017 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SafeTimer : NSObject

// aSelector不带参数
+ (SafeTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector repeats:(BOOL)yesOrNo;

+ (SafeTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(dispatch_block_t)aBlock repeats:(BOOL)yesOrNo;

- (void)invalidate;
- (BOOL)isValid;
- (void)addTimerForRunLoopMode:(NSRunLoopMode)mode;
@end
