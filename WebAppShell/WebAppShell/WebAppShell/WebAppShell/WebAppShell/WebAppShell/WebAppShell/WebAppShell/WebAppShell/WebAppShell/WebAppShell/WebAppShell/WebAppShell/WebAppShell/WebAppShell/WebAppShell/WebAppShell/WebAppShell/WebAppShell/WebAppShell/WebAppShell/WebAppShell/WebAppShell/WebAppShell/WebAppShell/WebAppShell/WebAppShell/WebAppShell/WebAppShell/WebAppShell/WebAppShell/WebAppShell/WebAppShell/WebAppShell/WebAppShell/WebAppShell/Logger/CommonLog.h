//
//  CommonLog.h
//  Commons
//
//  Created by daixiang on 13-2-12.
//  Copyright (c) 2013年 YY Inc. All rights reserved.
//

#ifndef Commons_CommonLog_h
#define Commons_CommonLog_h

#if 0

enum
{
    CommonLogLevelVerbose = 0,
    CommonLogLevelDebug,
    CommonLogLevelInfo,
    CommonLogLevelWarning,
    CommonLogLevelError,
    CommonLogLevelFatal
};

typedef unsigned int CommonLogLevel;

enum
{
    CommonLogCategoryNone = (unsigned long long)0,
    CommonLogCategoryDefault = (unsigned long long)1 << 0,
    CommonLogCategoryUtils = (unsigned long long)1 << 1,
    CommonLogCategoryHTTP = (unsigned long long)1 << 2,
    CommonLogCategoryLoader = (unsigned long long)1 << 3,
    CommonLogCategoryFramework = (unsigned long long)1 << 4,
    CommonLogCategoryUI = (unsigned long long)1 << 5,
};

typedef unsigned long long CommonLogCategory;


#if defined(__cplusplus)
extern "C"
{
    extern void __common_log__(CommonLogCategory category, CommonLogLevel level, NSString *format, ...);
    extern void __log__(CommonLogCategory category, CommonLogLevel level, NSString *format, va_list args);
    extern void __setLogLevel__(CommonLogLevel level);
    extern void __setForceLogLevel__(CommonLogLevel level);
    extern void __setFileLogEnabled__(BOOL enabled);
    extern void __setFileLogLevel__(CommonLogLevel level);
    extern void __registerLogCategory__(CommonLogCategory *newCategory, NSString *newCategoryString);
    extern void __enableLogCategory__(CommonLogCategory category);
    extern void __disableLogCategory__(CommonLogCategory category);
    extern void __setLogCategory__(CommonLogCategory category);
    extern void __setLogFileDir__(NSString *dir);
    extern NSString *__getLogFilePath__();
}
#else
extern void __common_log__(CommonLogCategory category, CommonLogLevel level, NSString *format, ...);
extern void __log__(CommonLogCategory category, CommonLogLevel level, NSString *format, va_list args);
extern void __setLogLevel__(CommonLogLevel level);
extern void __setForceLogLevel__(CommonLogLevel level);
extern void __setFileLogEnabled__(BOOL enabled);
extern void __setFileLogLevel__(CommonLogLevel level);
extern void __registerLogCategory__(CommonLogCategory *newCategory, NSString *newCategoryString);
extern void __enableLogCategory__(CommonLogCategory category);
extern void __disableLogCategory__(CommonLogCategory category);
extern void __setLogCategory__(CommonLogCategory category);
extern void __setLogFileDir__(NSString *dir);
extern NSString *__getLogFilePath__();
#endif

#define DEFAULT_LOG_LEVEL CommonLogLevelVerbose
#define DEFAULT_LOG_CATEGORY (CommonLogCategoryDefault | CommonLogCategoryUtils | CommonLogCategoryHTTP | CommonLogCategoryLoader | CommonLogCategoryFramework | CommonLogCategoryUI)

#define DEFAULT_FILE_LOG_LEVEL CommonLogLevelInfo

#define COMMON_LOG(category, level, format, arg...) __common_log__(category, level, format, ##arg)

//大于等于此level的log会被输出，强制输出的级别不受此控制
#define SET_LOG_LEVEL(level) __setLogLevel__(level)

//设置强制输出的log级别。大于等于此级别的log会强制输出，而不管SET_LOG_LEVEL和SET_LOG_CATEGORY的设置，默认为CommonLogLevelInfo
#define SET_FORCE_LOG_LEVEL(level) __setForceLogLevel__(level)

//是否使用文件log，默认为打开
#define SET_FILE_LOG_ENABLED(enabled) __setFileLogEnabled__(enabled)

//在启用文件log时，文件输出的级别。满足当前log级别和类别条件时才起作用
#define SET_FILE_LOG_LEVEL(level) __setFileLogLevel__(level)

//注册一个新的log类别。新类别的值会写入到传入的category中
#define REGISTER_LOG_CATEGORY(category, categoryString) __registerLogCategory__(&category, categoryString)

//打开指定类别的log输出
#define ENABLE_LOG_CATEGORY(category) __enableLogCategory__(category)

//直接设置log类别，指定类别的log才会输出
#define SET_LOG_CATEGORY(category) __setLogCategory__(category)

//关闭指定类别的log输出
#define DISABLE_LOG_CATEGORY(category) __disableLogCategory__(category)

//设置log文件目录
#define SET_LOG_FILE_DIR(dir) __setLogFileDir__(dir)

//当前log文件路径
#define GET_LOG_FILE_PATH() __getLogFilePath__()

//使用默认类别输出
#define LOG_VERBOSE(format, arg...) COMMON_LOG(CommonLogCategoryDefault, CommonLogLevelVerbose, format, ##arg)
#define LOG_DEBUG(format, arg...) COMMON_LOG(CommonLogCategoryDefault, CommonLogLevelDebug, format, ##arg)
#define LOG_INFO(format, arg...) COMMON_LOG(CommonLogCategoryDefault, CommonLogLevelInfo, format, ##arg)
#define LOG_WARNING(format, arg...) COMMON_LOG(CommonLogCategoryDefault, CommonLogLevelWarning, format, ##arg)
#define LOG_ERROR(format, arg...) COMMON_LOG(CommonLogCategoryDefault, CommonLogLevelError, format, ##arg)
#define LOG_FATAL(format, arg...) COMMON_LOG(CommonLogCategoryDefault, CommonLogLevelFatal, format, ##arg)

#define LOG_UI_VERBOSE(format, arg...) COMMON_LOG(CommonLogCategoryUI, CommonLogLevelVerbose, format, ##arg)
#define LOG_UI_DEBUG(format, arg...) COMMON_LOG(CommonLogCategoryUI, CommonLogLevelDebug, format, ##arg)
#define LOG_UI_INFO(format, arg...) COMMON_LOG(CommonLogCategoryUI, CommonLogLevelInfo, format, ##arg)
#define LOG_UI_WARNING(format, arg...) COMMON_LOG(CommonLogCategoryUI, CommonLogLevelWarning, format, ##arg)
#define LOG_UI_ERROR(format, arg...) COMMON_LOG(CommonLogCategoryUI, CommonLogLevelError, format, ##arg)

#define LOG_UTILS_DEBUG(format, arg...) COMMON_LOG(CommonLogCategoryUtils, CommonLogLevelDebug, format, ##arg)
#define LOG_UTILS_INFO(format, arg...) COMMON_LOG(CommonLogCategoryUtils, CommonLogLevelInfo, format, ##arg)
#define LOG_UTILS_WARNING(format, arg...) COMMON_LOG(CommonLogCategoryUtils, CommonLogLevelWarning, format, ##arg)
#define LOG_UTILS_ERROR(format, arg...) COMMON_LOG(CommonLogCategoryUtils, CommonLogLevelError, format, ##arg)

#endif

#endif

