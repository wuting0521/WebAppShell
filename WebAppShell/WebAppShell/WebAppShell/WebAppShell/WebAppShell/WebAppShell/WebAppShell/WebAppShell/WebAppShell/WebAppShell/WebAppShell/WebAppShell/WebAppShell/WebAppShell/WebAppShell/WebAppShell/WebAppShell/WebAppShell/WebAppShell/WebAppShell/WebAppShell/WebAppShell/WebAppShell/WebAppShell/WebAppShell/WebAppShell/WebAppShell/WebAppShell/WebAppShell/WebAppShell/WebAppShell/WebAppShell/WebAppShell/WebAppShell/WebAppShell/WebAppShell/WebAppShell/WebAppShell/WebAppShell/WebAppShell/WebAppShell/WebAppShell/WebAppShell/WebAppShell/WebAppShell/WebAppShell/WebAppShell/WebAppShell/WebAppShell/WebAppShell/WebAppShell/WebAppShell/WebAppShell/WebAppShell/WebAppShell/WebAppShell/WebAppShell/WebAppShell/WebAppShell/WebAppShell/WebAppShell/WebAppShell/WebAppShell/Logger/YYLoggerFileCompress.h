//
//  YYLoggerFileCompress.h
//  YYMobileFramework
//
//  Created by xianmingchen on 16/5/13.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LogCompressResult)
{
    LogCompressResultOK = 0,
    LogCompressResultParamError,
    LogCompressResultCreateZipFail,
    LogCompressResultCompressFail,
};

@interface YYLoggerFileCompress : NSObject
+ (LogCompressResult)compressFiles:(NSArray *)filePathArray toPath:(NSString *)toPath deleFileAfterCompress:(BOOL)shouldDelete;
@end
