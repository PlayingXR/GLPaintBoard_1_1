//
//  WXHGLLineModel.h
//  GLPaintBoard
//
//  Created by 伍小华 on 2017/5/18.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WXHGLLineModel : NSObject
@property (nonatomic) BOOL isErase;
@property (nonatomic, assign) CGFloat size;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSArray *pointArray;
@end
