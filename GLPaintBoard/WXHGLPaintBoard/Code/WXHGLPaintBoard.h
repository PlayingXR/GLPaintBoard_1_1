//
//  WXHGLPaintBoard.h
//  GLPaintDemo
//
//  Created by 伍小华 on 2017/5/17.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^CompleteBlock)(NSArray *lineArray, UIImage *paintImage,UIImage *image);
typedef void (^CancelBlock) (void);
typedef NS_ENUM(NSInteger, WXHGLPaintBoardType)
{
    WXHGLPaintBoardTypeNormal,
    WXHGLPaintBoardTypeImage,
};
@interface WXHGLPaintBoard : UIView
@property (nonatomic, assign) WXHGLPaintBoardType type;

- (void)cancelActionBlock:(CancelBlock)cancelBlock;
- (void)completeActionBlock:(CompleteBlock)completeBlock;

- (void)dismiss;

- (void)showWithImage:(UIImage *)image lineArray:(NSArray *)lineArray;
- (void)show;
@end
