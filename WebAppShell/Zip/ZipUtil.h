//
//  ZipUtils.h
//  YY2
//
//  Created by WuWenqing on 13-4-7.
//  Copyright (c) 2013年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZipUtil : NSObject

+ (NSData *)gzipData:(NSData *)pUncompressedData withGZipHeader:(BOOL)withGZipHeader;
+ (BOOL)gzipCompressFile:(NSString *)filePath
             zipFilePath:(NSString *)zipFilePath
              withHeader:(BOOL)withHeader;

+ (NSData *)uncompressZippedData:(NSData *)compressedData;

+ (BOOL)gzipUnCompressZippedFromFile:(NSString *)zipFilePath toFilePath:(NSString *)filePath;

@end
