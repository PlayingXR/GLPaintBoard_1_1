//
//  WXHGLPaintBoard.h
//  GLPaintDemo
//
//  Created by 伍小华 on 2017/5/17.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, WXHGLPaintBoardType)
{
    WXHGLPaintBoardTypeNormal,
    WXHGLPaintBoardTypeImage,
};
@interface WXHGLPaintBoard : UIView
@property (nonatomic, assign) WXHGLPaintBoardType type;
@end
