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
@property (nonatomic, strong) WXHGLPaintBoard *board;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"开始" forState:UIControlStateNormal];
    [button setTitle:@"退出" forState:UIControlStateSelected];
    button.frame = CGRectMake(0, 0, 100, 64);
    button.backgroundColor = [UIColor brownColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.board.frame = self.view.bounds;
}
- (void)buttonAction:(UIButton *)button
{
    button.selected = !button.selected;
    if (button.selected) {
        button.backgroundColor = [UIColor greenColor];
        self.board = [[WXHGLPaintBoard alloc] initWithFrame:self.view.bounds];
        self.board.type = WXHGLPaintBoardTypeNormal;
        [self.view insertSubview:self.board belowSubview:button];
    } else {
        button.backgroundColor = [UIColor brownColor];
        [self.board removeFromSuperview];
        self.board = nil;
    }
}
@end
