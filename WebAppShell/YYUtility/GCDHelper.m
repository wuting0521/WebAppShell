//
//  GCDHelper.m
//  YYMobileFramework
//
//  Created by wuwei on 14/7/18.
//  Copyright (c) 2014年 YY Inc. All rights reserved.
//

#import "GCDHelper.h"

void dispatch_main_sync_safe(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

void dispatch_main_async_safe(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}
