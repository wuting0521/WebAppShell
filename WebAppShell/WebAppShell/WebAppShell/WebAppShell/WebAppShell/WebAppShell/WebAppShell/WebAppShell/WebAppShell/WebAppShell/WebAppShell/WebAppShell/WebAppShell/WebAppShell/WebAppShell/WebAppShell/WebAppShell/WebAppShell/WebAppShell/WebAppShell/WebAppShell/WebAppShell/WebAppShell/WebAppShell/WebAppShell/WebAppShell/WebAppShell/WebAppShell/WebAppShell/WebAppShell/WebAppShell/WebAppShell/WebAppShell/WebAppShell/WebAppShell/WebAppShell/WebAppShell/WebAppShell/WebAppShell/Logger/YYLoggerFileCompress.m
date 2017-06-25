//
//  YYLoggerFileCompress.m
//  YYMobileFramework
//
//  Created by xianmingchen on 16/5/13.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import "YYLoggerFileCompress.h"
#import "ZipArchive.h"

@implementation YYLoggerFileCompress

+ (LogCompressResult)compressFiles:(NSArray *)filePathArray toPath:(NSString *)toPath deleFileAfterCompress:(BOOL)shouldDelete
{
    LogCompressResult result = LogCompressResultOK;
    
    do
    {
        if ([filePathArray count] <= 0 || !toPath)
        {
            result = LogCompressResultParamError;
            break;
        }
        
        ZipArchive *zipArchive = [[ZipArchive alloc] init];
        BOOL createSucc =  [zipArchive CreateZipFile2:toPath];
        if (!createSucc)
        {
            result = LogCompressResultCreateZipFail;
            break;
        }
        
        for (NSString *filePath in filePathArray)
        {
            [zipArchive addFileToZip:filePath newname:filePath.lastPathComponent];
        }
        BOOL compressSucc = [zipArchive CloseZipFile2];
        if (!compressSucc)
        {
            result = LogCompressResultCompressFail;
            break;
        }
        
    }while (0);
    
    if (shouldDelete)
    {
        for (NSString *filePath in filePathArray)
        {
            if ([filePath.pathExtension isEqualToString:@"log"])
            {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            
        }
    }
    
    return result;
}

@end
