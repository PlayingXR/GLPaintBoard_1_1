


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "WXHGLLineModel.h"

@interface WXHGLPaintingView : UIView

@property (nonatomic, assign, readonly) BOOL isPainting;
@property (nonatomic, assign) BOOL isErase;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineSize;
@property (nonatomic, assign) CGFloat eraserSize;

@property (nonatomic, strong, readonly) NSMutableArray<WXHGLLineModel *> *lineArray;
@property (nonatomic, strong, readonly) NSMutableArray *deletedLineArray;

/**
 撤销现在的绘制，后退
 */
- (void)undo;

/**
 重做之前的绘制，前进
 */
- (void)redo;

/**
 清除屏幕

 @param allowRedo 是否允许重做
 */
- (void)clear:(BOOL)allowRedo;


/**
 截图

 @return image
 */
- (UIImage *)snapshot;


/**
 重画备份的数据

 @param lineArray 点数据
 */
- (void)reloadLineFromLineArray:(NSArray<WXHGLLineModel *> *)lineArray;
@end
