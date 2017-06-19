//
//  GCDHelper.h
//  YYMobileFramework
//
//  Created by wuwei on 14/7/18.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

void dispatch_main_sync_safe(dispatch_block_t block);

void dispatch_main_async_safe(dispatch_block_t block);
