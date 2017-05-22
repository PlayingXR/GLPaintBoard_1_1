//
//  MacroDefine.h
//  ClassSystemStudent
//
//  Created by wxh on 2016/12/29.
//  Copyright © 2016年 Jerry. All rights reserved.
//

#ifndef MacroDefine_h
#define MacroDefine_h

//-------------------打印日志-------------------------
//DEBUG 模式下打印日志,当前行
#ifdef DEBUG
# define DLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
# define DEALLOCLOG NSLog(@"%@ dealloc...",[NSString stringWithUTF8String:class_getName([self class])])
#else
# define DLOG(...)
# define DEALLOCLOG
#endif

//-----------------------------------------------
//-------------------屏幕-------------------------
/** 屏幕伸缩度（Retina时值为2,非Retina值为1）*/
#define SCREEN_SCALE [UIScreen mainScreen].scale

//考虑转屏的影响，按照实际屏幕方向（UIDeviceOrientation）的宽高
#define SCREEN [UIScreen mainScreen]
#define SCREEN_BOUNDS [UIScreen mainScreen].bounds
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

#define DEVICE_WIDTH (SCREEN_WIDTH < SCREEN_HEIGHT ? SCREEN_WIDTH : SCREEN_HEIGHT)
#define DEVICE_HEIGHT (SCREEN_WIDTH > SCREEN_HEIGHT ? SCREEN_WIDTH : SCREEN_HEIGHT)

#define SCREEN_WIDTH_SCALE_6 (DEVICE_WIDTH / 375.0)
#define SCREEN_HEIGHT_SCALE_6 (DEVICE_HEIGHT / 667.0)

#define WIDTH_SCALE_6_(x) (ceil(x * SCREEN_WIDTH_SCALE_6))
#define HEIGHT_SCALE_6_(x) (ceil(x * SCREEN_HEIGHT_SCALE_6))

#define STATUSBAR_HEIGHT ([UIApplication sharedApplication].statusBarFrame.size.height)
// 应用的实际宽高，除去“状态栏”
#define APPFRAME_HEIGHT ([UIScreen mainScreen].applicationFrame.size.height)
#define APPFRAME_WIDTH ([UIScreen mainScreen].applicationFrame.size.width)
//-----------------------------------------------------
//----------------------系统----------------------------
// 判断设备
#define DEVICE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? ipad: iphone
#define DEVICE_PAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define DEVICE_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

//判断iPhone的屏幕
#define DEVICE_SCREEN_I4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define DEVICE_SCREEN_I5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define DEVICE_SCREEN_I6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define DEVICE_SCREEN_PLUS ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)

//获取系统版本
#define VERSION_DEVICE [[UIDevice currentDevice] systemVersion]
#define VERSION_SYSTEM_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define VERSION_SYSTEM_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define VERSION_SYSTEM_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define VERSION_SYSTEM_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define VERSION_SYSTEM_LESS_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

//获取应用版本
#define APP_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define APP_NAME [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
#define APP_BUNDLE_ID [[NSBundle mainBundle] bundleIdentifier]
//----------------------------------------------------
//----------------------颜色---------------------------
// rgb颜色转换（16进制->10进制）
#define COLOR_RGB16(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define COLOR_RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define COLOR_RGB(r,g,b) COLOR_RGBA(r,g,b,1.0f)

#define COLOR_RANDOM KRGBColor(arc4random_uniform(256)/255.0,arc4random_uniform(256)/255.0,arc4random_uniform(256)/255.0)
//--------------------------------------------------------
//----------------------读取图片----------------------------
#define IMAGE_BUNDLE_TYPE(file,ext) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:file ofType:ext]]
#define IMAGE_BUNDLE(A) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:A ofType:nil]]
#define IMAGE_PATH(A) [UIImage imageWithContentsOfFile:A]
#define IMAGE_NAMED(image) [UIImage imageNamed:image]

//-----------------------------------------------------
//----------------------路径----------------------------
#define PATH_BUNDLE             ([[NSBundle mainBundle] bundlePath])
#define PATH_BUNDLE_(file)      ([PATH_BUNDLE stringByAppendingPathComponent:file])
#define PATH_TEMP               NSTemporaryDirectory()

#define PATH_DOCUMENT           [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define PATH_DOCUMENT_(file)    ([PATH_DOCUMENT stringByAppendingPathComponent:file])

#define PATH_CACHE              [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define PATH_CACHE_(file)       ([PATH_CACHE stringByAppendingPathComponent:file])

#define PATH_SEARCH             [kPathDocument stringByAppendingPathComponent:@"Search.plist"]
//-----------------------------------------------------
//----------------------空值----------------------------
//字符串是否为空
#define EMPTY_STRING(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )
//数组是否为空
#define EMPTY_ARRAY(array) (array == nil || [array isKindOfClass:[NSNull class]] || array.count == 0)
//字典是否为空
#define EMPTY_DIC(dic) (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys == 0)
//是否是空对象
#define EMPTY_OBJECT(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]] \
|| ([_object respondsToSelector:@selector(length)] && [(NSData *)_object length] == 0) \
|| ([_object respondsToSelector:@selector(count)] && [(NSArray *)_object count] == 0))
//---------------------------------------------------
//----------------------其他--------------------------
//NSString format

#define NSStringFromNumber_c( __v__ ) [NSString stringWithFormat:@"%@", @(__v__)]
#define NSStringFromObject_oc( __v__ ) [NSString stringWithFormat:@"%@", __v__]

//alert show
static inline void UIAlertViewShowMessage(NSString *message) { UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil]; [alert show]; }
//定义一个define函数
#define TT_RELEASE_CF_SAFELY(__REF) { if (nil != (__REF)) { CFRelease(__REF); __REF = nil; } }

#define  RESING_FIRST_RESPONDER  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder)to:nil from:nil forEvent:nil]

//弱引用/强引用
#define SELF_WEAK(type)   __weak typeof(type) weak##type = type;
#define SELF_STRONG(type) __strong typeof(type) type = weak##type;

//获取一段时间间隔
#define TIME_START CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
#define TIME_END   NSLog(@"Time: %f", CFAbsoluteTimeGetCurrent() - start)

#define NOTIFICATIONCENTER [NSNotificationCenter defaultCenter]
#define NOTIFICATIONCENTER_POST(_name) [[NSNotificationCenter defaultCenter] postNotificationName:_name object:nil userInfo:nil]
#define NOTIFICATIONCENTER_POST_OBJECT(_name,_object) [[NSNotificationCenter defaultCenter] postNotificationName:_name object:_object userInfo:nil]
#define NOTIFICATIONCENTER_POST_USERINFO(_name,_userInfo) [[NSNotificationCenter defaultCenter] postNotificationName:_name object:nil userInfo:_userInfo]
#define NOTIFICATIONCENTER_POST_OBJECT_USERINFO(_name,_object,_userInfo) [[NSNotificationCenter defaultCenter] postNotificationName:_name object:_object userInfo:_userInfo]
#define NOTIFICATIONCENTER_REMOVE_ALL [[NSNotificationCenter defaultCenter] removeObserver:self]
#define NOTIFICATIONCENTER_REMOVE(_name) [[NSNotificationCenter defaultCenter] removeObserver:self name:_name object:nil]


#define USERDEFAULTS [NSUserDefaults standardUserDefaults]
#define APPLICATION [UIApplication sharedApplication]
#define KEYWINDOW  [UIApplication sharedApplication].keyWindow
#define FILEMANAGER [NSFileManager defaultManager]

//方正黑体简体字体定义
#define FONT(F) [UIFont systemFontOfSize:F]
#define FONT_BOLD(F) [UIFont boldSystemFontOfSize:F]

//设置View的tag属性
#define VIEW_TAG(_OBJECT, _TAG) [_OBJECT viewWithTag : _TAG]

//获取当前语言
#define LOCAL_LANGUAGE ([[NSLocale preferredLanguages] objectAtIndex:0])
//程序的本地化,引用国际化的文件
#define LOCAL_STRING(x, ...) NSLocalizedString(x, nil)

//由角度获取弧度 有弧度获取角度
#define ANGLE_RADIAN(angle) (M_PI * (angle) / 180.0)
#define RADIAN_ANGLE(radian) (radian*180.0) / (M_PI)

//G－C－D
#define GCD_BACK(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
#define GCD_MAIN(block) dispatch_async(dispatch_get_main_queue(),block);
#define GCD_ONCE(tag,block) static dispatch_once_t once_##tag;dispatch_once(&once_##tag,block);
/*
--------------------
 GCD_BACK(^{
 NSLog(@"hello");
 });
--------------------
 GCD_ONCE(hello,^{
 NSLog(@"hello");
 });
 -------------------- 
 */


//使用ARC和不使用ARC
#if __has_feature(objc_arc)
//compiling with ARC
#else
// compiling without ARC
#endif

//判断是真机还是模拟器
#if TARGET_OS_IPHONE
//iPhone Device
#endif

#if TARGET_IPHONE_SIMULATOR
//iPhone Simulator
#endif

//--------------------------------------------------
//---------------------单例--------------------------
// @interface
#define SINGLE_INTERFACE(className) \
+ (className *)shared##className;

// @implementation
#define SINGLE_IMPLEMENTATION(className) \
\
static className *shared##className = nil; \
\
+ (className *)shared##className \
{ \
@synchronized(self) \
{ \
if (shared##className == nil) \
{ \
shared##className = [[self alloc] init]; \
} \
} \
\
return shared##className; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
@synchronized(self) \
{ \
if (shared##className == nil) \
{ \
shared##className = [super allocWithZone:zone]; \
return shared##className; \
} \
} \
\
return nil; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
}
//--------------------------------------------------

#endif /* MacroDefine_h */
