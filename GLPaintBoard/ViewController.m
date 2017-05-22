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

@property (nonatomic, strong) NSArray *lineArray;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) WXHGLPaintBoard *paintBoard;
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor brownColor];
    [button setTitle:@"草稿本" forState:UIControlStateNormal];
     button.frame = CGRectMake(50, 100, 100, 60);
    button.tag = 0;
    [self.view addSubview:button];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.backgroundColor = [UIColor brownColor];
    [button1 setTitle:@"照片涂鸦" forState:UIControlStateNormal];
    button1.frame = CGRectMake(200, 100, 100, 60);
    button1.tag = 1;
    [self.view addSubview:button1];
    [button1 addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.imageView.frame = self.view.bounds;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (_paintBoard) {
        return [self.paintBoard supportedInterfaceOrientations];
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}

- (void)buttonAction:(UIButton *)button
{
    if (button.tag == 0) {
        self.paintBoard.type = WXHGLPaintBoardTypeNormal;
    } else {
        self.paintBoard.type = WXHGLPaintBoardTypeImage;
        __weak ViewController *weakSelf = self;
        [self.paintBoard completeActionBlock:^(NSArray *lineArray, UIImage *paintImage, UIImage *image) {
            __strong ViewController *strongSelf = weakSelf;
            strongSelf.imageView.image = paintImage;
            strongSelf.lineArray = lineArray;
            strongSelf.image = image;
        }];
    }
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
