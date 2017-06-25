//
//  WAUserInterfaceViewControllerInstantiable.h
//  WebApp
//
//  Created by wuwei on 14-4-30.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WAUserInterfaceViewControllerInstantiable <NSObject>

@required
+ (UIViewController *)instantiateViewControllerWithJSONObject:(NSDictionary *)jsonObject
                                                        error:(NSError **)error;

@end