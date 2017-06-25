//
//  YYViewController.h
//  YYMobile
//
//  Created by wuwei on 14/6/11.
//  Copyright (c) 2014年 YY.inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YYViewController : UIViewController


#pragma mark - keyBroad

/**
 *  点击键盘外区域是否要隐藏键盘
 *  默认返回YES
 */
- (BOOL)touchViewToHideKeyBroad;

/** 
 *  键盘出现回调
 *  重写 call [supper onKeyBroadDidShow:kbSize]
 *  @param kbSize 键盘的大小
 */
- (void)onKeyBroadDidShow:(CGSize)kbSize NS_REQUIRES_SUPER;

- (void)onKeyBroadSizeChanged:(CGSize)kbSize;

/** 
 *  键盘隐藏回调
 *  重写 call [supper onKeyBroadDidShow:kbSize]
 */
- (void)onKeyBroadWillHide NS_REQUIRES_SUPER;

@end
