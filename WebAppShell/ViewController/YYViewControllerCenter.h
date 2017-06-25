//
//  YYViewControllerCenter.h
//  YYMobile
//
//  Created by zhenby on 7/9/14.
//  Copyright (c) 2014 YY.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  用于方便获取应用运行状态下，常用的ViewController对象，以及ViewController的跳转
 */
@interface YYViewControllerCenter : NSObject

/**
 * 当前用来presend其它ViewController的ViewController
 */
+ (UIViewController*)currentRootViewControllerInStack;

@end
