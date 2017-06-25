//
//  LogDefine.h
//  YYMobileFramework
//
//  Created by leo on 15-3-23.
//  Copyright (c) 2015年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYLogger.h"

@interface LogDefine : NSObject

@end

/*
//Log使用例子，以下几个均为合法Log
[YYLogger info:TGift message:...];
LogInfo(TGift,...);
LoginfoGift(...);
[YYLogger info:TAG(TGift,TNavigate) message:...];
 
//日志规范说明
1、使用Log必须要使用Tag，公用Tag定义在LogDefine.h中
2、Tag可以多个拼接使用，如TAG(TChannel,TNavigate)即为@"Channel|Navigate"；功能独立也可以拼接上自己的Tag，如TAG(TChannel,@"MyTag")
3、如果新功能Log较多，且Tag不适用已有Tag，可以讨论增加Tag
4、关于TNavigate、TNetSend等公用Tag，请尽量拼接使用，拼接上对应的模块Tag
5、增加了开发中使用Log，关键字LogInfoDev，在内部测试版会打Log，但对外发布不会在用户端打Log，由于Log较多，一些重复性较高的Log应该使用LogInfoDev或者LogVerbose
 
 公用Tag说明：
 1、	TNavigate为用户点击跳转和切换Activity是需要使用，如JoinChannel；是一个重要的共用Tag，可以判断用户行为，跳转是务必添加
 2、	TDataReport是数据上报相关，快速筛选数据上报
 3、	TNetSend和TNetReceive是网络收发包相关，请在网络请求和响应时加上。
*/

//Log相关的Tag分类
//Tag分类说明，以下每几行为一组Tag，TChannel、TIM...TBase为大类Tag，TGift为TChannel的子Tag
static NSString* const TChannel     = @"Channel";
static NSString* const TChat        = @"Chat";          //公屏

static NSString* const TIM          = @"IM";
static NSString* const TConversation    = @"Conversation";  //IM和群消息相关
static NSString* const TAddFriend   = @"AddFriend";     //添加好友
static NSString* const TAddGroup    = @"AddGroup";      //添加群
static NSString* const TFriendInfo  = @"FriendInfo";    //好友信息
static NSString* const TGroupInfo   = @"GroupInfo";     //群信息
static NSString* const TFriendList  = @"FriendList";    //好友列表
static NSString* const TGroupList   = @"GroupList";     //群列表


static NSString* const TAuth        = @"Auth";          //认证相关
static NSString* const TLogin       = @"Login";         //登录
static NSString* const TRegister    = @"Register";      //注册

static NSString* const TPersonal    = @"Personal";      //个人页面
static NSString* const TTaskCenter  = @"TaskCenter";    //任务中心
static NSString* const TMessageCenter   = @"MessageCenter"; //消息中心
static NSString* const TFavorite    = @"Favorite";      //个人的Favarite页面
static NSString* const TFollowee    = @"Followee";      //个人的Followee页面

static NSString* const TBase        = @"Base";          //公用的基础控件, 如果控件较大可以独立使用一个Tag，如下几个
static NSString* const TCategories  = @"Categories";    //基础控件Categories相关
static NSString* const TLiveNotification    = @"LiveNotification";
static NSString* const TControllers  = @"Controllers";        //公用的基础Controler控件
static NSString* const TJSON        = @"JSON";          //基础JSON相关
static NSString* const THTTP        = @"HTTP";          //基础HTTP下载控件
static NSString* const TPlugin        = @"Plugin";          //基础HTTP下载控件

//以上的Tag为分组Tag，以下Tag为独立Tag（具体见文件头的说明）
static NSString* const TApp         = @"App";           //Appdelegate等
static NSString* const TApplePush   = @"ApplePush";
static NSString* const TShare       = @"Share";         //第三方分享
static NSString* const TDatabase    = @"Database";      //数据库相关
static NSString* const TWebApp      = @"WebApp";        //WebApp相关
static NSString* const TLogUpload   = @"LogUpload";     //日志上传相关，包括Crash Log和反馈系统
static NSString* const TSDK         = @"SDK";           //和SDK交互相关，如sdk调用返回错误等
static NSString* const TMedia       = @"Media";         //流媒体相关
static NSString* const TLogger      = @"Logger";      //日志收集

//以下Tag为行为类Tag，和上面的Tag可以同时使用，如@"Gift|Action"，即为TAG(TGift,TAction)
static NSString* const TNavigate    = @"Navigate";    //跳转
static NSString* const TOperating    = @"Operating";    //操作跳转
static NSString* const TDataReport  = @"DataReport";    //数据上报
static NSString* const TNetSend     = @"NetSend";       //网络请求
static NSString* const TNetReceive  = @"NetReceive";    //网络返回
static NSString* const TPerf        = @"Perf";          //性能
static NSString * const TLocation = @"Location";     //位置请求相关
static NSString* const TConfig        = @"Config";
static NSString * const TIndex = @"Index";

static NSString* const TLive     = @"TLive";     //手机开播娱乐硬编
static NSString* const TVideoSrv     = @"VideoSrv";     //手机开播娱乐硬编
static NSString* const TOrder     = @"OrderSrv";     //手机开播娱乐硬编


typedef NS_ENUM(NSInteger, LogErrorCode)
{
    LogErrorCodeOK = 0,                             //上传成功
    LogErrorCodeUploadFail = -6,                    //上传失败
    LogErrorCodeDirNotExist = -8,                   //目录创建失败
    LogErrorCodeCompressZipFileFail = -10,          //压缩失败
    LogErrorCodeNotEnoughStorage = -11,             //磁盘空间不足
    LogErrorCodeNetworkException = -12,             //网络异常
    LogErrorCodeSwitchClose = -13,                  //日志开关为关
    LogErrorCodeCreateZipFail = -14,                //创建zip包失败
    LogErrorCodeCreateDeCompressFail = -15,         //解压单个小时zip文件失败
    LogErrorCodeCompressParamError = -16,           //压缩传参出错
    LogErrorCodeFeedbackCreateFileFail = -17,        //
};

//拼接多个Log Tag
#define TAG(tag1,tag2) ([[tag1 stringByAppendingString:@"|"]stringByAppendingString:tag2])
