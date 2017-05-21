//
//  ViewController.m
//  GLPaintDemo
//
//  Created by 伍小华 on 2017/5/17.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import "ViewController.h"
#import "WXHGLPaintBoard.h"

@interface ViewController ()<UIScrollViewDelegate>
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) NSArray *lineArray;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) WXHGLPaintBoard *paintBoard;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.button.backgroundColor = [UIColor brownColor];
    [self.view addSubview:self.button];
    [self.button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.button.frame = self.view.bounds;
}
- (void)buttonAction
{
    __weak ViewController *weakSelf = self;
    [self.paintBoard completeActionBlock:^(NSArray *lineArray, UIImage *paintImage, UIImage *image) {
        __strong ViewController *strongSelf = weakSelf;
        [strongSelf.button setImage:paintImage forState:UIControlStateNormal];
        strongSelf.lineArray = lineArray;
        strongSelf.image = image;
    }];
    [self.paintBoard showWithImage:self.image lineArray:self.lineArray];
}
- (WXHGLPaintBoard *)paintBoard
{
    if (!_paintBoard) {
        _paintBoard = [[WXHGLPaintBoard alloc] initWithFrame:self.view.bounds];
        _paintBoard.type = WXHGLPaintBoardTypeImage;
    }
    return _paintBoard;
}
@end
