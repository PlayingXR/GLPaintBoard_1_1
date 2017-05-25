//
//  WXHGLPaintBoard.m
//  GLPaintDemo
//
//  Created by 伍小华 on 2017/5/17.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import "WXHGLPaintBoard.h"
#import "WXHGLPaintingView.h"
#import <AVFoundation/AVFoundation.h>
#import "MacroDefine.h"

#define PaintHeaderViewBackgroundColor [UIColor colorWithRed:103.0/255.0 green:220.0/255.0 blue:195.0/255.0 alpha:1.0]
#define PaintFooterViewBackgroundColor [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]
#define PaintViewBackgroundColor [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7]

static const CGFloat headerViewHeight = 64.0;
static const CGFloat footerViewHeight = 44.0;
static const CGFloat buttonWidth = 40.0;

static const CGFloat lineSize = 4.0;
static const CGFloat eraserSize = 44.0;

@interface WXHGLPaintBoard ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) WXHGLPaintingView *paintingView;
@property (nonatomic, strong) UIImageView       *imageView;
@property (nonatomic, strong) UIImage           *image;

@property (nonatomic, strong) UIView            *headerView;
@property (nonatomic, strong) UIView            *footerView;
@property (nonatomic, strong) UIView            *colorView;

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *undoButton;
@property (nonatomic, strong) UIButton *redoButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *eraserButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *penButton;
@property (nonatomic, strong) UIButton *completeButton;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, strong) NSArray *colorArray;

@property (nonatomic, copy) CancelBlock cancelBlock;
@property (nonatomic, copy) CompleteBlock completeBlock;

@property (nonatomic, assign) BOOL isColorShow;
@property (nonatomic, assign) NSInteger colorIndex;

@property (nonatomic, assign) BOOL isPopGestureRecognizerEnabled;

@end
@implementation WXHGLPaintBoard

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {

        self.colorArray = @[[UIColor colorWithRed:252/255.0 green:78/255.0 blue:81/255.0 alpha:1.0],
                            [UIColor colorWithRed:255/255.0 green:253/255.0 blue:93/255.0 alpha:1.0],
                            [UIColor colorWithRed:80/255.0 green:236/255.0 blue:82/255.0 alpha:1.0],
                            [UIColor colorWithRed:80/255.0 green:233/255.0 blue:233/255.0 alpha:1.0],
                            [UIColor colorWithRed:72/255.0 green:78/255.0 blue:233/255.0 alpha:1.0],
                            [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]];
        self.colorIndex = 5;
        
        [self addSubview:self.paintingView];
        [self addSubview:self.colorView];
        [self addSubview:self.headerView];
        [self addSubview:self.footerView];
        
        [self.paintingView addObserver:self forKeyPath:@"isErase" options:NSKeyValueObservingOptionNew context:nil];
        [self.paintingView addObserver:self forKeyPath:@"isPainting" options:NSKeyValueObservingOptionNew context:nil];
        [self.paintingView addObserver:self forKeyPath:@"lineArray" options:NSKeyValueObservingOptionNew context:nil];
        [self.paintingView addObserver:self forKeyPath:@"deletedLineArray" options:NSKeyValueObservingOptionNew context:nil];
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeSubviewFrame)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
        
        
    }
    return self;
}

- (void)dealloc
{
    [self.paintingView removeObserver:self forKeyPath:@"isErase" context:nil];
    [self.paintingView removeObserver:self forKeyPath:@"isPainting" context:nil];
    [self.paintingView removeObserver:self forKeyPath:@"lineArray" context:nil];
    [self.paintingView removeObserver:self forKeyPath:@"deletedLineArray" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"WXHGLPaintBoard dealloc!!");
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"isErase"]) {
        NSNumber *isErase = [change valueForKey:NSKeyValueChangeNewKey];
        self.eraserButton.selected = isErase.boolValue;
        
        if (isErase.boolValue) {
            [self.penButton setImage:[UIImage imageNamed:@"paint_pen.png"] forState:UIControlStateNormal];
        } else {
            NSString *imageName = [NSString stringWithFormat:@"paint_pen_%i.png",self.colorIndex];
            [self.penButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        }
    } else if ([keyPath isEqualToString:@"isPainting"]) {
        [self hiddenColorView];
    }else if ([keyPath isEqualToString:@"lineArray"]) {
        [self refreshButtonState];
    } else if ([keyPath isEqualToString:@"deletedLineArray"]) {
        [self refreshButtonState];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
#pragma mark - Private
- (void)refreshButtonState
{
    if ([self.paintingView.lineArray count]) {
        self.undoButton.enabled = YES;
        self.eraserButton.enabled = YES;
    } else {
        self.undoButton.enabled = NO;
        self.eraserButton.enabled = NO;
        self.paintingView.isErase = NO;
    }
    if (_imageView.image || [self.paintingView.lineArray count]) {
        self.clearButton.enabled = YES;
    } else {
        self.clearButton.enabled = NO;
    }
    
    if ([self.paintingView.deletedLineArray count] || self.image) {
        self.redoButton.enabled = YES;
    } else {
        self.redoButton.enabled = NO;
    }
}
- (void)resizeSubviewFrame
{
    if (self.type == WXHGLPaintBoardTypeImage) {
        self.frame = CGRectMake(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT);
        self.headerView.frame = CGRectMake(0, 0, DEVICE_WIDTH, headerViewHeight);
        self.footerView.frame = CGRectMake(0, DEVICE_HEIGHT - footerViewHeight, DEVICE_WIDTH, footerViewHeight);
    } else {
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        self.headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, headerViewHeight);
        self.footerView.frame = CGRectMake(0, SCREEN_HEIGHT - footerViewHeight, SCREEN_WIDTH, footerViewHeight);
    }
    
    _imageView.frame = CGRectMake(0,
                                  headerViewHeight,
                                  DEVICE_WIDTH,
                                  DEVICE_HEIGHT - headerViewHeight - footerViewHeight);
    
    self.paintingView.frame = CGRectMake(0,
                                         headerViewHeight,
                                         DEVICE_HEIGHT,
                                         DEVICE_HEIGHT);
    
    self.colorView.frame = CGRectMake(0, SCREEN_HEIGHT - footerViewHeight*2 - 10, SCREEN_WIDTH, footerViewHeight);
    
    CGFloat count = (CGFloat)[self.colorArray count];
    CGFloat space = (SCREEN_WIDTH - count*buttonWidth)/(count + 1);
    
    for (NSInteger i = 0; i < count; i++) {
        UIView *view = [self.colorView viewWithTag:1000+i];
        view.center = CGPointMake(space + buttonWidth/2.0+(space+buttonWidth)*i, footerViewHeight / 2.0);
    }
    
    [self resizeButtonFrame];
}

- (void)resizeButtonFrame
{
    CGFloat border = 20.0;
    CGFloat header_top = headerViewHeight - buttonWidth;
    CGFloat footer_top = (footerViewHeight - buttonWidth ) / 2.0;
    
    self.cancelButton.frame = CGRectMake(border, header_top, buttonWidth, buttonWidth);
    self.undoButton.center = CGPointMake(self.headerView.center.x, buttonWidth/2.0 + header_top);
    self.redoButton.frame = CGRectMake(self.headerView.bounds.size.width - buttonWidth - border, header_top, buttonWidth, buttonWidth);
    
    self.clearButton.frame = CGRectMake(border, footer_top, buttonWidth, buttonWidth);
    if (self.type == WXHGLPaintBoardTypeNormal) {
        self.cameraButton.hidden = YES;
        self.completeButton.hidden = YES;
        
        self.eraserButton.center = CGPointMake(self.footerView.center.x, footerViewHeight/2.0);
        self.penButton.frame = CGRectMake(self.footerView.bounds.size.width - buttonWidth - border, footer_top, buttonWidth, buttonWidth);
    } else if (self.type == WXHGLPaintBoardTypeImage) {
        CGFloat space = floor((self.footerView.bounds.size.width - buttonWidth*5 - border *2)/4.0);
        
        self.cameraButton.hidden = NO;
        self.completeButton.hidden = NO;
        
        self.cameraButton.center = CGPointMake(self.footerView.center.x, footerViewHeight/2.0);
        self.eraserButton.frame = CGRectMake(self.cameraButton.frame.origin.x - buttonWidth - space, footer_top, buttonWidth, buttonWidth);
        
        self.completeButton.frame = CGRectMake(self.footerView.bounds.size.width - buttonWidth - border, footer_top, buttonWidth, buttonWidth);
        self.penButton.frame = CGRectMake(self.completeButton.frame.origin.x - buttonWidth - space, footer_top, buttonWidth, buttonWidth);
    }
}
- (void)cancelButtonAction
{
    [self hiddenColorView];
    if (self.cancelBlock) {
        self.cancelBlock();
        self.cancelBlock = nil;
    }
    [self dismiss];
}
- (void)undoButtonAction
{
    [self hiddenColorView];
    [self.paintingView undo];
    [self refreshButtonState];
}
- (void)redoButtonAction
{
    [self hiddenColorView];
    if (self.image) {
        _imageView.image = self.image;
        self.image = nil;
    }
    [self.paintingView redo];
    [self refreshButtonState];
}
- (void)clearButtonAction
{
    [self hiddenColorView];
    if (_imageView.image) {
        self.image = _imageView.image;
        _imageView.image = nil;
    }
    [self.paintingView clear:YES];
    self.paintingView.isErase = NO;
    [self refreshButtonState];
}
- (void)eraserButtonAction
{
    [self hiddenColorView];
    self.paintingView.isErase = YES;
}
- (void)cameraButtonAction
{
    [self hiddenColorView];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        if ([[AVCaptureDevice class] respondsToSelector:@selector(authorizationStatusForMediaType:)])
        {
            AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authorizationStatus == AVAuthorizationStatusRestricted
                || authorizationStatus == AVAuthorizationStatusDenied)
            {
                // 没有权限
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"没有拍照权限(您可以在设置 > 通用 > 访问限制 > 相机 中开启)!"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                return;
            }
        }
        
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
//        self.imagePicker.allowsEditing = YES;
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.imagePicker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        
        UIViewController *vc = [self currentViewController];
        [vc presentViewController:self.imagePicker animated:YES completion:nil];
    }
}
- (void)penButtonAction
{
    if (self.paintingView.isErase) {
        self.paintingView.isErase = NO;
    } else {
        if (self.isColorShow) {
            [self hiddenColorView];
        } else {
            [self showColorView];
        }
    }
}
- (void)completeButtonAction
{
    [self hiddenColorView];
    if (self.completeBlock) {
        UIImage *image = nil;
        if ([self.paintingView.lineArray count] || _imageView.image) {
            image = [self currentPanitImage];
        }
        self.completeBlock(self.paintingView.lineArray, image, self.imageView.image);
        self.completeBlock = nil;
    }
    [self dismiss];
}
- (UIImage *)currentPanitImage
{
    UIImage *snapshot = [self.paintingView snapshot];
    UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, YES, 0);
    //白色背景
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextFillRect(context, self.imageView.bounds);
    
    [self.imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    [snapshot drawInRect:self.paintingView.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    UIGraphicsEndImageContext();
    return image;
}
- (void)colorButtonAction:(UIButton *)button
{
    NSInteger index = button.tag - 1000;
    self.colorIndex = index;
    self.paintingView.lineColor = self.colorArray[index];
    [self hiddenColorView];
    
    NSString *imageName = [NSString stringWithFormat:@"paint_pen_%i.png",self.colorIndex];
    [self.penButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}
- (void)showColorView
{
    if (!self.isColorShow) {
        self.colorView.alpha = 0;
        CGRect colorViewFrame = self.colorView.frame;
        colorViewFrame.origin.y = SCREEN_HEIGHT;
        self.colorView.frame = colorViewFrame;
        colorViewFrame.origin.y = SCREEN_HEIGHT - footerViewHeight*2 -10;
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.colorView.frame = colorViewFrame;
                             self.colorView.alpha = 1;
                         } completion:^(BOOL finished) {
                             self.isColorShow = YES;
                         }];
    }
}
- (void)hiddenColorView
{
    if (self.isColorShow) {
        CGRect colorViewFrame = self.colorView.frame;
        colorViewFrame.origin.y = SCREEN_HEIGHT;
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.colorView.frame = colorViewFrame;
                             self.colorView.alpha = 0;
                         } completion:^(BOOL finished) {
                             self.isColorShow = NO;
                         }];
    }
}

#pragma mark - Public
- (void)cancelActionBlock:(CancelBlock)cancelBlock
{
    self.cancelBlock = cancelBlock;
}
- (void)completeActionBlock:(CompleteBlock)completeBlock
{
    self.completeBlock = completeBlock;
}
- (void)dismiss
{
    [self dismissImagePickerController];
    [self dismissAnimation];
}
- (void)show
{
    [self showWithImage:nil lineArray:nil];
}
- (void)showWithImage:(UIImage *)image lineArray:(NSArray *)lineArray
{
    self.image = nil;
    
    [self rotateDevice];
    [self resizeSubviewFrame];
    [self refreshButtonState];
    
    UIViewController *currentViewController = [self currentViewController];
    self.isPopGestureRecognizerEnabled = currentViewController.navigationController.interactivePopGestureRecognizer.enabled;
    currentViewController.navigationController.interactivePopGestureRecognizer.enabled = NO;
    [currentViewController.view addSubview:self];

    if (self.type == WXHGLPaintBoardTypeImage) {
        self.imageView.image = image;
        if ([lineArray count]) {
            [self.paintingView performSelector:@selector(reloadLineFromLineArray:) withObject:lineArray afterDelay:0.1];
        }
    }
    
    [self showAnimation];
}

- (void)showAnimation
{
    self.headerView.alpha = 0;
    self.footerView.alpha = 0;
    _paintingView.alpha = 0;
    _imageView.alpha = 0;
    
    __block CGRect headerFrame = self.headerView.frame;
    __block CGRect footerFrame = self.footerView.frame;
    headerFrame.origin.y = - headerFrame.size.height;
    footerFrame.origin.y = SCREEN_HEIGHT;
    self.headerView.frame = headerFrame;
    self.footerView.frame = footerFrame;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.headerView.alpha = 1;
                         self.footerView.alpha = 1;
                         _paintingView.alpha = 1;
                         _imageView.alpha = 1;
                         
                         headerFrame.origin.y = 0;
                         footerFrame.origin.y = SCREEN_HEIGHT - footerFrame.size.height;
                         self.headerView.frame = headerFrame;
                         self.footerView.frame = footerFrame;
                         
                         self.backgroundColor = PaintViewBackgroundColor;
                     } completion:^(BOOL finished) {
                         _isShow = YES;
                     }];
}
- (void)dismissAnimation
{
    CGRect headerFrame = self.headerView.frame;
    CGRect footerFrame = self.footerView.frame;
    headerFrame.origin.y = - headerFrame.size.height;
    footerFrame.origin.y = SCREEN_HEIGHT;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.headerView.alpha = 0;
                         self.footerView.alpha = 0;
                         _paintingView.alpha = 0;
                         _imageView.alpha = 0;
                         
                         self.headerView.frame = headerFrame;
                         self.footerView.frame = footerFrame;
                         
                         self.backgroundColor = [UIColor clearColor];
                     } completion:^(BOOL finished) {
                         _isShow = NO;
                         UIViewController *currentViewController = [self currentViewController];
                         currentViewController.navigationController.interactivePopGestureRecognizer.enabled = self.isPopGestureRecognizerEnabled;
                         
                         [self removeFromSuperview];
                     }];
}
#pragma mark - Device Rotate
- (void)rotateDevice
{
    if (self.type == WXHGLPaintBoardTypeImage) {
        if (SCREEN_WIDTH > SCREEN_HEIGHT) {
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.type == WXHGLPaintBoardTypeImage) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissImagePickerController];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
//    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    self.imageView.image = [UIImage imageWithData:imageData];
    [self dismissImagePickerController];
    [self refreshButtonState];
}
- (void)dismissImagePickerController
{
    if (self.imagePicker) {
        [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.imagePicker = nil;
        [self rotateDevice];
    }
}
#pragma mark - Setter / Getter
- (WXHGLPaintingView *)paintingView
{
    if (!_paintingView) {
        _paintingView = [[WXHGLPaintingView alloc] init];
        _paintingView.lineColor = self.colorArray[self.colorIndex];
        _paintingView.lineSize = lineSize;
        _paintingView.eraserSize = eraserSize;
    }
    return _paintingView;
}
- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, headerViewHeight, SCREEN_WIDTH, SCREEN_HEIGHT - headerViewHeight - footerViewHeight)];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self insertSubview:_imageView belowSubview:self.paintingView];
    }
    return _imageView;
}
- (void)setType:(WXHGLPaintBoardType)type
{
    if (_type != type) {
        _type = type;
        
        if (_type == WXHGLPaintBoardTypeImage) {
            [self imageView];
        } else {
            [_imageView removeFromSuperview];
            _imageView = nil;
        }
        [self resizeButtonFrame];
    }
}

- (UIView *)headerView
{
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = PaintHeaderViewBackgroundColor;
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
        _footerView.backgroundColor = PaintFooterViewBackgroundColor;
        [_footerView addSubview:self.clearButton];
        [_footerView addSubview:self.eraserButton];
        [_footerView addSubview:self.cameraButton];
        [_footerView addSubview:self.penButton];
        [_footerView addSubview:self.completeButton];
    }
    return _footerView;
}
- (UIView *)colorView
{
    if (!_colorView) {
        _colorView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - footerViewHeight*2 - 10, SCREEN_WIDTH, footerViewHeight)];
        _colorView.alpha = 0;
        
        CGFloat count = (CGFloat)[self.colorArray count];
        CGFloat space = (SCREEN_WIDTH - count*buttonWidth)/(count + 1);

        for (NSInteger i = 0; i < count; i++) {
            UIButton *button = [self button];
            button.center = CGPointMake(space + buttonWidth/2.0+(space+buttonWidth)*i, footerViewHeight / 2.0);
            button.backgroundColor = self.colorArray[i];
            button.layer.cornerRadius = 5.0;
            button.clipsToBounds = YES;
            button.tag = 1000+i;
            [_colorView addSubview:button];
            [button addTarget:self action:@selector(colorButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return _colorView;
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
        NSString *imageName = [NSString stringWithFormat:@"paint_pen_%i.png",self.colorIndex];
        [_penButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
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
#pragma mark - Others
//获取当前显示的viewcontroller
- (UIViewController *)currentViewController
{
    UIWindow *window = [self currentWindow];
    return [self p_nextTopForViewController:window.rootViewController];
}
- (UIViewController *)p_nextTopForViewController:(UIViewController *)inViewController {
    while (inViewController.presentedViewController) {
        inViewController = inViewController.presentedViewController;
    }
    
    if ([inViewController isKindOfClass:[UITabBarController class]]) {
        UIViewController *selectedVC = [self p_nextTopForViewController:((UITabBarController *)inViewController).selectedViewController];
        return selectedVC;
    } else if ([inViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *selectedVC = [self p_nextTopForViewController:((UINavigationController *)inViewController).visibleViewController];
        return selectedVC;
    } else {
        return inViewController;
    }
}

//获取当前主window
- (UIWindow *)currentWindow
{
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    return window;
}
@end
