//
//  WXHGLPaintBoard.m
//  GLPaintDemo
//
//  Created by 伍小华 on 2017/5/17.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import "WXHGLPaintBoard.h"
#import "WXHGLPaintingView.h"

static const CGFloat headerViewHeight = 64.0;
static const CGFloat footerViewHeight = 44.0;
static const CGFloat buttonWidth = 40.0;
static const CGFloat lineSize = 4.0;
static const CGFloat eraserSize = 20.0;

@interface WXHGLPaintBoard ()
@property (nonatomic, strong) WXHGLPaintingView *paintingView;
@property (nonatomic, strong) UIImageView       *imageView;

@property (nonatomic, strong) UIView            *headerView;
@property (nonatomic, strong) UIView            *footerView;


@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *undoButton;
@property (nonatomic, strong) UIButton *redoButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *eraserButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *penButton;
@property (nonatomic, strong) UIButton *completeButton;

@end
@implementation WXHGLPaintBoard

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
        
        [self addSubview:self.paintingView];
        [self addSubview:self.headerView];
        [self addSubview:self.footerView];
        
        [self.paintingView addObserver:self forKeyPath:@"isErase" options:NSKeyValueObservingOptionNew context:nil];
        [self.paintingView addObserver:self forKeyPath:@"lineArray" options:NSKeyValueObservingOptionNew context:nil];
        [self.paintingView addObserver:self forKeyPath:@"deletedLineArray" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.headerView.frame = CGRectMake(0, 0, self.bounds.size.width, headerViewHeight);
    self.footerView.frame = CGRectMake(0, self.bounds.size.height - footerViewHeight, self.bounds.size.width, footerViewHeight);
    
    self.imageView.frame = CGRectMake(0,
                                      headerViewHeight,
                                      self.bounds.size.width,
                                      self.bounds.size.height - headerViewHeight - footerViewHeight);
    self.paintingView.frame = self.imageView.frame;
    
    [self resizeButtonFrame];
}
- (void)dealloc
{
    [self.paintingView removeObserver:self forKeyPath:@"isErase" context:nil];
    [self.paintingView removeObserver:self forKeyPath:@"lineArray" context:nil];
    [self.paintingView removeObserver:self forKeyPath:@"deletedLineArray" context:nil];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"isErase"]) {
        NSNumber *isErase = [change valueForKey:NSKeyValueChangeNewKey];
        self.eraserButton.selected = isErase.boolValue;
    } else if ([keyPath isEqualToString:@"lineArray"]) {
        NSArray *lineArray = [change valueForKey:NSKeyValueChangeNewKey];
        if ([lineArray count]) {
            self.clearButton.enabled = YES;
            self.undoButton.enabled = YES;
            self.eraserButton.enabled = YES;
        } else {
            self.clearButton.enabled = NO;
            self.undoButton.enabled = NO;
            self.eraserButton.enabled = NO;
            self.paintingView.isErase = NO;
        }
    } else if ([keyPath isEqualToString:@"deletedLineArray"]) {
        NSArray *deletedLineArray = [change valueForKey:NSKeyValueChangeNewKey];
        if ([deletedLineArray count]) {
            self.redoButton.enabled = YES;
        } else {
            self.redoButton.enabled = NO;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
#pragma mark - Private
- (void)resizeButtonFrame
{
    CGFloat border = 20.0;
    CGFloat header_top = 22.0;
    CGFloat footer_top = (self.footerView.frame.size.height - buttonWidth ) / 2.0;
    
    self.cancelButton.frame = CGRectMake(border, header_top, buttonWidth, buttonWidth);
    self.undoButton.center = CGPointMake(self.headerView.center.x, buttonWidth/2.0 + header_top);
    self.redoButton.frame = CGRectMake(self.headerView.bounds.size.width - buttonWidth - border, header_top, buttonWidth, buttonWidth);
    
    self.clearButton.frame = CGRectMake(border, footer_top, buttonWidth, buttonWidth);
    if (self.type == WXHGLPaintBoardTypeNormal) {
        self.cameraButton.hidden = YES;
        self.completeButton.hidden = YES;
        
        self.eraserButton.center = CGPointMake(self.footerView.center.x, buttonWidth/2.0 + footer_top);
        self.penButton.frame = CGRectMake(self.footerView.bounds.size.width - buttonWidth - border, footer_top, buttonWidth, buttonWidth);
    } else if (self.type == WXHGLPaintBoardTypeImage) {
        CGFloat space = floor((self.footerView.bounds.size.width - buttonWidth*5 - border *2)/4.0);
        
        self.cameraButton.hidden = NO;
        self.completeButton.hidden = NO;
        
        self.cameraButton.center = CGPointMake(self.footerView.center.x, buttonWidth/2.0 + footer_top);
        self.eraserButton.frame = CGRectMake(self.cameraButton.frame.origin.x - buttonWidth - space, footer_top, buttonWidth, buttonWidth);
        
        self.completeButton.frame = CGRectMake(self.footerView.bounds.size.width - buttonWidth - border, footer_top, buttonWidth, buttonWidth);
        self.penButton.frame = CGRectMake(self.completeButton.frame.origin.x - buttonWidth - space, footer_top, buttonWidth, buttonWidth);
    }
}
- (void)cancelButtonAction
{
    
}
- (void)undoButtonAction
{
    [self.paintingView undo];
}
- (void)redoButtonAction
{
    [self.paintingView redo];
}
- (void)clearButtonAction
{
    [self.paintingView clear];
    self.paintingView.isErase = NO;
}
- (void)eraserButtonAction
{
    self.paintingView.isErase = YES;
}
- (void)cameraButtonAction
{
    
}
- (void)penButtonAction
{
    self.paintingView.isErase = NO;
}
- (void)completeButtonAction
{
    
}
#pragma mark - Setter / Getter
- (WXHGLPaintingView *)paintingView
{
    if (!_paintingView) {
        _paintingView = [[WXHGLPaintingView alloc] initWithFrame:self.bounds];
        _paintingView.lineColor = [UIColor colorWithRed:0.1 green:0.2 blue:0.3 alpha:1];
        _paintingView.lineSize = lineSize;
        _paintingView.eraserSize = eraserSize;
    }
    return _paintingView;
}
- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}
- (void)setType:(WXHGLPaintBoardType)type
{
    if (_type != type) {
        _type = type;
        
        if (_type == WXHGLPaintBoardTypeNormal) {
            if (_imageView) {
                [_imageView removeFromSuperview];
                _imageView = nil;
            }
        } else if (_type == WXHGLPaintBoardTypeImage) {
            if (!_imageView) {
                [self insertSubview:self.imageView belowSubview:self.paintingView];
            }
        }
        [self resizeButtonFrame];
    }
}

- (UIView *)headerView
{
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = [UIColor colorWithRed:103.0/255.0 green:220.0/255.0 blue:195.0/255.0 alpha:1.0];
        [_headerView addSubview:self.cancelButton];
        [_headerView addSubview:self.undoButton];
        [_headerView addSubview:self.redoButton];
    }
    return _headerView;
}
- (UIView *)footerView
{
    if (!_footerView) {
        _footerView = [[UIView alloc] init];
        _footerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        [_footerView addSubview:self.clearButton];
        [_footerView addSubview:self.eraserButton];
        [_footerView addSubview:self.cameraButton];
        [_footerView addSubview:self.penButton];
        [_footerView addSubview:self.completeButton];
    }
    return _footerView;
}
- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [self button];
        [_cancelButton setImage:[UIImage imageNamed:@"paint_cancel.png"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}
- (UIButton *)undoButton
{
    if (!_undoButton) {
        _undoButton = [self button];
        [_undoButton setImage:[UIImage imageNamed:@"paint_undo.png"] forState:UIControlStateNormal];
        [_undoButton addTarget:self action:@selector(undoButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _undoButton.enabled = NO;
    }
    return _undoButton;
}
- (UIButton *)redoButton
{
    if (!_redoButton) {
        _redoButton = [self button];
        [_redoButton setImage:[UIImage imageNamed:@"paint_redo.png"] forState:UIControlStateNormal];
        [_redoButton addTarget:self action:@selector(redoButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _redoButton.enabled = NO;
    }
    return _redoButton;
}
- (UIButton *)clearButton
{
    if (!_clearButton) {
        _clearButton = [self button];
        [_clearButton setImage:[UIImage imageNamed:@"paint_clear.png"] forState:UIControlStateNormal];
        [_clearButton addTarget:self action:@selector(clearButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _clearButton.enabled = NO;
    }
    return _clearButton;
}
- (UIButton *)eraserButton
{
    if (!_eraserButton) {
        _eraserButton = [self button];
        [_eraserButton setImage:[UIImage imageNamed:@"paint_eraser.png"] forState:UIControlStateNormal];
        [_eraserButton setImage:[UIImage imageNamed:@"paint_eraser_h.png"] forState:UIControlStateSelected];
        [_eraserButton addTarget:self action:@selector(eraserButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _eraserButton.enabled = NO;
    }
    return _eraserButton;
}
- (UIButton *)cameraButton
{
    if (!_cameraButton) {
        _cameraButton = [self button];
        [_cameraButton setImage:[UIImage imageNamed:@"paint_camera.png"] forState:UIControlStateNormal];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _cameraButton.hidden = YES;
    }
    return _cameraButton;
}
- (UIButton *)penButton
{
    if (!_penButton) {
        _penButton = [self button];
        [_penButton setImage:[UIImage imageNamed:@"paint_pen.png"] forState:UIControlStateNormal];
        [_penButton addTarget:self action:@selector(penButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _penButton;
}
- (UIButton *)completeButton
{
    if (!_completeButton) {
        _completeButton = [self button];
        [_completeButton setImage:[UIImage imageNamed:@"paint_complete.png"] forState:UIControlStateNormal];
        [_completeButton addTarget:self action:@selector(completeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _completeButton.hidden = YES;
    }
    return _completeButton;
}

- (UIButton *)button
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.frame = CGRectMake(0, 0, 40, 40);
    return button;
}

@end
