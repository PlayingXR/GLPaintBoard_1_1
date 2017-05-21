


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "WXHGLLineModel.h"

@interface WXHGLPaintingView : UIView

@property (nonatomic, assign) BOOL isErase;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineSize;
@property (nonatomic, assign) CGFloat eraserSize;

@property (nonatomic, strong) NSMutableArray<WXHGLLineModel *> *lineArray;
@property (nonatomic, strong) NSMutableArray *deletedLineArray;


//重做之前的绘制，前进
- (void)redo;
//撤销现在的绘制，后退
- (void)undo;
//清除屏幕
- (void)clear;

- (UIImage*)snapshot;
- (void)renderLineFromLineArray:(NSArray<WXHGLLineModel *> *)pointArray;
@end
