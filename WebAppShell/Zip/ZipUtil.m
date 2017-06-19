//
//  ZipUtils.m
//  YY2
//
//  Created by WuWenqing on 13-4-7.
//  Copyright (c) 2013年 YY Inc. All rights reserved.
//

#import "ZipUtil.h"

#include <zlib.h>

// http://www.clintharris.net/2009/how-to-gzip-data-in-memory-using-objective-c/
// http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html

@implementation ZipUtil

+ (NSData *)gzipData:(NSData *)pUncompressedData withGZipHeader:(BOOL)withGZipHeader
{
    if (!pUncompressedData || [pUncompressedData length] == 0) {
        return nil;
    }
    
    z_stream zlibStreamStruct;
    zlibStreamStruct.zalloc = Z_NULL; // Set zalloc, zfree, and opaque to Z_NULL so
    zlibStreamStruct.zfree = Z_NULL; // that when we call deflateInit2 they will be
    zlibStreamStruct.opaque = Z_NULL; // updated to use default allocation functions.
    zlibStreamStruct.total_out = 0; // Total number of output bytes produced so far
    zlibStreamStruct.next_in = (Bytef*)[pUncompressedData bytes]; // Pointer to input bytes
    zlibStreamStruct.avail_in = (uInt)[pUncompressedData length]; // Number of input bytes left to process
    
    int initError = Z_OK;
    if (withGZipHeader) {
        initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
    } else {
        initError = deflateInit(&zlibStreamStruct, Z_DEFAULT_COMPRESSION);
    }
    if (initError != Z_OK) {
        NSString *errorMsg = nil;
        switch (initError) {
            case Z_STREAM_ERROR:
                errorMsg = @"Invalid parameter passed in to function.";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"Insufficient memory.";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                break;
            default:
                errorMsg = @"Unknown error code.";
                break;
        }
        return nil;
    }
    
    // Create output memory buffer for compressed data. The zlib documentation states that
    // destination buffer size must be at least 0.1% larger than avail_in plus 12 bytes.
    NSMutableData *compressedData = [NSMutableData dataWithLength:[pUncompressedData length] * 1.01 + 12];
    
    int deflateStatus;
    do
    {
        // Store location where next byte should be put in next_out
        zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;
        
        // Calculate the amount of remaining free space in the output buffer
        // by subtracting the number of bytes that have been written so far
        // from the buffer's total capacity
        zlibStreamStruct.avail_out = (uInt)([compressedData length] - zlibStreamStruct.total_out);
        
        /* deflate() compresses as much data as possible, and stops/returns when
         the input buffer becomes empty or the output buffer becomes full. If
         deflate() returns Z_OK, it means that there are more bytes left to
         compress in the input buffer but the output buffer is full; the output
         buffer should be expanded and deflate should be called again (i.e., the
         loop should continue to rune). If deflate() returns Z_STREAM_END, the
         end of the input stream was reached (i.e.g, all of the data has been
         compressed) and the loop should stop. */
        deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);
        
    } while ( deflateStatus == Z_OK );
    
    // Check for zlib error and convert code to usable error message if appropriate
    if (deflateStatus != Z_STREAM_END)
    {
        NSString *errorMsg = nil;
        switch (deflateStatus)
        {
            case Z_ERRNO:
                errorMsg = @"Error occured while reading file.";
                break;
            case Z_STREAM_ERROR:
                errorMsg = @"The stream state was inconsistent (e.g., next_in or next_out was NULL).";
                break;
            case Z_DATA_ERROR:
                errorMsg = @"The deflate data was invalid or incomplete.";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"Memory could not be allocated for processing.";
                break;
            case Z_BUF_ERROR:
                errorMsg = @"Ran out of output buffer for writing compressed bytes.";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                break;
            default:
                errorMsg = @"Unknown error code.";
                break;
        }
        
        // Free data structures that were dynamically created for the stream.
        deflateEnd(&zlibStreamStruct);
        
        return nil;
    }
    // Free data structures that were dynamically created for the stream.
    deflateEnd(&zlibStreamStruct);
    [compressedData setLength: zlibStreamStruct.total_out];
//    SdkLogDebug(@"%s: Compressed file from %d KB to %d KB", __func__, [pUncompressedData length]/1024, [compressedData length]/1024);
    
    return compressedData;     
}


+ (BOOL)gzipCompressFile:(NSString *)filePath
             zipFilePath:(NSString *)zipFilePath
              withHeader:(BOOL)withHeader
{
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
	NSData* compressData = [ZipUtil gzipData:data withGZipHeader:withHeader];
	[[NSFileManager defaultManager] createFileAtPath:zipFilePath contents:nil attributes:nil];
	NSFileHandle *writeFile = [NSFileHandle fileHandleForWritingAtPath:zipFilePath];
	if (writeFile == nil){
		return NO;
	}
    
    @try {
        [writeFile truncateFileAtOffset:0];
        [writeFile writeData:compressData];
        [writeFile closeFile];
    }
    @catch (NSException *exception) {
    }
    @finally {
        [writeFile closeFile];
    }
    
    return YES;
}

+ (BOOL)gzipUnCompressZippedFromFile:(NSString *)zipFilePath toFilePath:(NSString *)filePath
{
    BOOL result = NO;

    NSData *data = [NSData dataWithContentsOfFile:zipFilePath options:NSDataReadingMappedIfSafe error:nil];
    NSData* unCompressData = [ZipUtil uncompressZippedData:data];
    

    result = [unCompressData writeToFile:filePath atomically:NO];
    
    return result;
}

+ (NSData *)uncompressZippedData:(NSData *)compressedData {
    
    if ([compressedData length] == 0) return compressedData;
    
    unsigned long full_length = [compressedData length];
    unsigned long half_length = [compressedData length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[compressedData bytes];
    strm.avail_in = (uInt)[compressedData length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    
    while (!done) {
        
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            
            [decompressed increaseLengthBy: half_length];
        }
        
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        
        if (status == Z_STREAM_END) {
            
            done = YES;
        } else if (status != Z_OK) {
            
            break;
        }
    }
    
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done) {
        
        [decompressed setLength: strm.total_out];
        
        return [NSData dataWithData: decompressed];
    } else {
        
        return nil;  
    }
}

@end
