
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

#import "WXHGLPaintingView.h"
#import "shaderUtil.h"
#import "fileUtil.h"
#import "debug.h"

//CONSTANTS:

#define kBrushOpacity		1.0

// Shaders
enum {
    PROGRAM_POINT,
    NUM_PROGRAMS
};

enum {
	UNIFORM_MVP,
    UNIFORM_POINT_SIZE,
    UNIFORM_VERTEX_COLOR,
    UNIFORM_TEXTURE,
	NUM_UNIFORMS
};

enum {
	ATTRIB_VERTEX,
	NUM_ATTRIBS
};

typedef struct {
	char *vert, *frag;
	GLint uniform[NUM_UNIFORMS];
	GLuint id;
} programInfo_t;

programInfo_t program[NUM_PROGRAMS] = {
    { "point.vsh",   "point.fsh" },     // PROGRAM_POINT
};


// Texture
typedef struct {
    GLuint id;
    GLsizei width, height;
} textureInfo_t;


@interface WXHGLPaintingView()
{
	//后帧缓存像素的宽高
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	//渲染缓存，帧缓存
	GLuint viewRenderbuffer, viewFramebuffer;
	
	textureInfo_t brushTexture;     //画笔的纹理

    CGPoint _points[5];
    
    //VBO（顶点缓存）
    GLuint vboId;
    
    BOOL initialized;
    NSMutableArray *_pointArray;
}
@end

@implementation WXHGLPaintingView
static GLfloat*		_vertexBuffer = NULL;
static NSUInteger	_vertexMax = 64;

//只有[CAEAGLLayer class]类型的layer菜支持在其上描绘OpenGL内容。
+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.multipleTouchEnabled = YES;
        [self setupLayer];

        _eraserSize = 20.0;
        _lineSize = 4.0;
        _lineColor = [UIColor redColor];
        
        //配置放大因子
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        panGesture.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:panGesture];
        
        NSArray * array = @[@(UISwipeGestureRecognizerDirectionLeft),
                            @(UISwipeGestureRecognizerDirectionRight),
                            @(UISwipeGestureRecognizerDirectionUp),
                            @(UISwipeGestureRecognizerDirectionDown)];
        
        for (NSNumber * number in array) {
            UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
            swipeGesture.numberOfTouchesRequired = 3;
            swipeGesture.direction = [number integerValue];
            [self addGestureRecognizer:swipeGesture];
            [swipeGesture requireGestureRecognizerToFail:panGesture];
        }
    }
    return self;
}
- (BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
    
    if (!initialized) {
        initialized = [self initGL];
    } else {
        [self resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
    [self clearScreen];
}
- (void)dealloc
{
    [self destoryRenderAndFrameBuffer];
}

#pragma mark - Private
//设置渲染Layer
- (void)setupLayer
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    //CALayer默认是透明的，必须将它设为不透明才能让其可见
    eaglLayer.opaque = NO;
    
    //设置描绘属性，在这里设置不维持渲染内容以及颜色格式为RGBA8
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @YES,//表示保持呈现的内容
                                     kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!context || ![EAGLContext setCurrentContext:context]) {
        NSLog(@"Faild to initialize OpenGLES 2.0 context");
    }
}

//设置着色器
- (void)setupShaders
{
	for (int i = 0; i < NUM_PROGRAMS; i++)
	{
		char *vsrc = readFile(pathForResource(program[i].vert));
		char *fsrc = readFile(pathForResource(program[i].frag));
		GLsizei attribCt = 0;
		GLchar *attribUsed[NUM_ATTRIBS];
		GLint attrib[NUM_ATTRIBS];
		GLchar *attribName[NUM_ATTRIBS] = {
			"inVertex",
		};
		const GLchar *uniformName[NUM_UNIFORMS] = {
			"MVP", "pointSize", "vertexColor", "texture",
		};
		
		// auto-assign known attribs
		for (int j = 0; j < NUM_ATTRIBS; j++)
		{
			if (strstr(vsrc, attribName[j]))
			{
				attrib[attribCt] = j;
				attribUsed[attribCt++] = attribName[j];
			}
		}
		
        //创建着色器
		glueCreateProgram(vsrc, fsrc,
                          attribCt, (const GLchar **)&attribUsed[0], attrib,
                          NUM_UNIFORMS, &uniformName[0], program[i].uniform,
                          &program[i].id);
		free(vsrc);
		free(fsrc);
        
        if (i == PROGRAM_POINT)
        {
            //使用着色器
            glUseProgram(program[PROGRAM_POINT].id);
            
            //清除纹理
            glUniform1i(program[PROGRAM_POINT].uniform[UNIFORM_TEXTURE], 0);
            
            // viewing matrices
            GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
            GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
            GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
            
            //MVP矩阵
            glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
        }
	}
    
    glError();
}

//创建一个纹理
- (textureInfo_t)textureFromName:(NSString *)name
{
    CGImageRef		brushImage;
	CGContextRef	brushContext;
	GLubyte			*brushData;
	size_t			width, height;
    GLuint          texId;
    textureInfo_t   texture;

    brushImage = [UIImage imageNamed:name].CGImage;

    width = CGImageGetWidth(brushImage);
    height = CGImageGetHeight(brushImage);

    if(brushImage) {
        //创建纹理内存
        brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
        //使用位图上下文，绑定纹理内存
        brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
        //把图片绘制到位图上下文，使纹理内存存储图片数据
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
        CGContextRelease(brushContext);
        
        //申请一个纹理ID
        glGenTextures(1, &texId);
        //绑定纹理ID
        glBindTexture(GL_TEXTURE_2D, texId);
        //开启缩小滤波器
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        //为绑定纹理ID的内存配置数据
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
        free(brushData);
        
        texture.id = texId;
        texture.width = (int)width;
        texture.height = (int)height;
    } else {
        texture.id = 0;
        texture.width = 0;
        texture.height = 0;
    }
    
    return texture;
}

- (BOOL)initGL
{
    //创建FBO（Frame Buffer Object)和渲染缓存
    //申请缓存ID
	glGenFramebuffers(1, &viewFramebuffer);
	glGenRenderbuffers(1, &viewRenderbuffer);
	
    //绑定缓存到申请好的ID
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	
    //为渲染缓存配置数据
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
    //将渲染缓存装配到GL_COLOR_ATTACHMENT0这个装配点上
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, viewRenderbuffer);
	
    //获取渲染的宽度、高度
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
		
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		return NO;
	}
    
    //设置视口
    glViewport(0, 0, backingWidth, backingHeight);
    
    //创建VBO（Vertex Buffer Object）
    glGenBuffers(1, &vboId);//申请缓存ID
    
    //加载笔头的纹理
    brushTexture = [self textureFromName:@"paint_particle.png"];
    
    //设置着色器
    [self setupShaders];
    
    return YES;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
	//绑定渲染缓存
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    //配置渲染缓存数据
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
        NSLog(@"Failed to make complete framebuffer objectz %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    //配置矩阵
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    glUseProgram(program[PROGRAM_POINT].id);
    //设置MVP矩阵
    glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    
    //视口
    glViewport(0, 0, backingWidth, backingHeight);
	
    return YES;
}
//设置线条的颜色
- (void)setupBrushColor:(UIColor *)color size:(CGFloat)size isErase:(BOOL)isErase
{
    //启用着色器
    glUseProgram(program[PROGRAM_POINT].id);
    GLfloat brushColor[4];
    if (isErase) {
        brushColor[0] = 0;
        brushColor[1] = 0;
        brushColor[2] = 0;
        brushColor[3] = 0;
        size = size * self.contentScaleFactor;
        
        //开启颜色混合
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ZERO);
    } else {
        
        CGFloat r, g, b, a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        brushColor[0] = r * kBrushOpacity;
        brushColor[1] = g * kBrushOpacity;
        brushColor[2] = b * kBrushOpacity;
        brushColor[3] = a * kBrushOpacity;
        size = size * self.contentScaleFactor;
        
        //开启颜色混合
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }
    //笔画大小
    glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], size);
    
    //画笔颜色
    glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
}

//释放缓存
- (void)destoryRenderAndFrameBuffer
{
    // Destroy framebuffers and renderbuffers
    if (viewFramebuffer) {
        glDeleteFramebuffers(1, &viewFramebuffer);
        viewFramebuffer = 0;
    }
    if (viewRenderbuffer) {
        glDeleteRenderbuffers(1, &viewRenderbuffer);
        viewRenderbuffer = 0;
    }
    
    // texture
    if (brushTexture.id) {
        glDeleteTextures(1, &brushTexture.id);
        brushTexture.id = 0;
    }
    
    //vertexBuffer
    if (_vertexBuffer != NULL) {
        free(_vertexBuffer);
        _vertexBuffer = NULL;
        _vertexMax = 64;
    }
    
    // vbo
    if (vboId) {
        glDeleteBuffers(1, &vboId);
        vboId = 0;
    }

    // tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
}

- (void)clearFramebuffer
{
    [EAGLContext setCurrentContext:context];
    
    // Clear the buffer
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

//清除屏幕
- (void)clearScreen
{
    self.lineArray = nil;
    _pointArray = nil;
    self.deletedLineArray = nil;
    [self clearFramebuffer];
    [self presentRenderbuffer];
}
- (void)renderLineFromVertexBuffer:(GLfloat *)vertexBuffer vertexCount:(NSUInteger)vertexCount
{
    //绑定顶点缓存
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    //为顶点缓存配置数据
    glBufferData(GL_ARRAY_BUFFER, vertexCount*2*sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
    //启用顶点缓存
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    //从缓存中取顶点给顶点着色器
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    //启用着色器
    glUseProgram(program[PROGRAM_POINT].id);
    
    //开始绘制
    glDrawArrays(GL_POINTS, 0, (int)vertexCount);
}
- (void)presentRenderbuffer
{
    //绑定渲染缓存
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    
    //将渲染好的数据显示到屏幕
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderLineFromPointArray:(NSArray<WXHGLLineModel *> *)pointArray
{
    GLfloat*    vertexBuffer = NULL;
    NSUInteger  vertexCount = 0;
    
    [self clearFramebuffer];
    
    for (WXHGLLineModel *model in pointArray) {
        vertexCount = [model.pointArray count];
        
        if(vertexBuffer == NULL) {
            vertexBuffer = malloc(vertexCount * 2 * sizeof(GLfloat));
        } else {
            vertexBuffer = realloc(vertexBuffer, vertexCount * 2 * sizeof(GLfloat));
        }
        
        NSUInteger i = 0;
        for(NSString *string in model.pointArray) {
            
            CGPoint point = CGPointFromString(string);
            
            vertexBuffer[2 * i + 0] = point.x;
            vertexBuffer[2 * i + 1] = point.y;
            i++;
        }
        
        [self setupBrushColor:model.color size:model.size isErase:model.isErase];
        [self renderLineFromVertexBuffer:vertexBuffer vertexCount:vertexCount];
    }
    
    [self presentRenderbuffer];
    
    free(vertexBuffer);
    vertexBuffer = NULL;
}

- (void)recordLine:(NSArray *)pointArray color:(UIColor *)color size:(CGFloat)size isErase:(BOOL)isErase
{
    WXHGLLineModel *model = [[WXHGLLineModel alloc] init];
    model.isErase = isErase;
    model.pointArray = [pointArray copy];
    model.color = color;
    model.size = size;
    [self willChangeValueForKey:@"lineArray"];
    [self.lineArray addObject:model];
    [self didChangeValueForKey:@"lineArray"];
}

#pragma mark - Public

//重做之前的绘制，前进
- (void)redo
{
    if ([self.deletedLineArray count]) {
        id object = [self.deletedLineArray lastObject];
        if ([object isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)object;
            self.lineArray = [array mutableCopy];
        } else if ([object isKindOfClass:[WXHGLLineModel class]]) {
            [self willChangeValueForKey:@"lineArray"];
            [self.lineArray addObject:object];
            [self didChangeValueForKey:@"lineArray"];
        }
        [self willChangeValueForKey:@"deletedLineArray"];
        [self.deletedLineArray removeLastObject];
        [self didChangeValueForKey:@"deletedLineArray"];
        
        [self renderLineFromPointArray:self.lineArray];
    }
}
//撤销现在的绘制，后退
- (void)undo
{
    if ([self.lineArray count]) {
        WXHGLLineModel *lineModel = [self.lineArray lastObject];
        [self willChangeValueForKey:@"deletedLineArray"];
        [self.deletedLineArray addObject:lineModel];
        [self didChangeValueForKey:@"deletedLineArray"];
        
        [self willChangeValueForKey:@"lineArray"];
        [self.lineArray removeLastObject];
        [self didChangeValueForKey:@"lineArray"];
        
        [self renderLineFromPointArray:self.lineArray];
    }
}
//清除
- (void)clear
{
    //清除路径
    if ([self.lineArray count]) {
        [self willChangeValueForKey:@"deletedLineArray"];
        [self.deletedLineArray addObject:self.lineArray];
        [self didChangeValueForKey:@"deletedLineArray"];
    }
    self.lineArray = nil;
    _pointArray = nil;
    [self clearFramebuffer];
    [self presentRenderbuffer];
}
#pragma mark - 手势操作
- (void)swipeGestureAction:(UISwipeGestureRecognizer *)swipeGesture
{
    [self clear];
}
- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture
{
    static NSUInteger index = 0;
    CGPoint point = [panGesture locationInView:panGesture.view];
    CGRect  bounds = [self bounds];
    point.y = bounds.size.height - point.y;
    
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        index = 0;
        _points[0] = point;
        _pointArray = [NSMutableArray array];
        //启用着色器
        glUseProgram(program[PROGRAM_POINT].id);
        
        if (self.isErase) {
            [self setupBrushColor:[UIColor clearColor] size:self.eraserSize isErase:YES];
        } else {
            [self setupBrushColor:self.lineColor size:self.lineSize isErase:NO];
        }
    } else if (panGesture.state == UIGestureRecognizerStateChanged) {
        
        index++;
        _points[index] = point;
        
        if (index == 4) {
            _points[3] = CGPointMake((_points[2].x + _points[4].x)/2.0, (_points[2].y + _points[4].y)/2.0);
            [self renderLinesFromPoints:_points[0] controlPoint1:_points[1] controlPoint2:_points[2] toPoint:_points[3]];
            
            _points[0] = _points[3];
            _points[1] = _points[4];
            index = 1;
        }
        
    } else if (panGesture.state == UIGestureRecognizerStateEnded ||
               panGesture.state == UIGestureRecognizerStateCancelled)
    {
        index++;
        _points[index] = point;
        
        CGPoint points[4];
        for (NSInteger i = 0; i < 4; i++) {
            if (i <= index) {
                points[i] = points[i];
            } else {
                points[i] = points[index];
            }
        }
        [self renderLinesFromPoints:points[0] controlPoint1:points[1] controlPoint2:points[2] toPoint:points[3]];
        
        if (self.isErase) {
            [self recordLine:_pointArray color:[UIColor clearColor] size:self.eraserSize isErase:self.isErase];
        } else {
            [self recordLine:_pointArray color:self.lineColor size:self.lineSize isErase:self.isErase];
        }
        
        _pointArray = nil;
        self.deletedLineArray = nil;
    }
}
//两点之间贝赛尔曲线插值
- (void)renderLinesFromPoints:(CGPoint)fromPoint
                controlPoint1:(CGPoint)controlPoint1
                controlPoint2:(CGPoint)controlPoint2
                      toPoint:(CGPoint)toPoint
{
    NSUInteger count,vertexCount = 0;
    
    [EAGLContext setCurrentContext:context];
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    // Convert locations from Points to Pixels
    CGFloat scale = self.contentScaleFactor;
    fromPoint.x *= scale;
    fromPoint.y *= scale;
    
    controlPoint1.x *= scale;
    controlPoint1.y *= scale;
    
    controlPoint2.x *= scale;
    controlPoint2.y *= scale;
    
    toPoint.x *= scale;
    toPoint.y *= scale;
    
    // Allocate vertex array buffer
    if(_vertexBuffer == NULL)
        _vertexBuffer = malloc(_vertexMax * 2 * sizeof(GLfloat));

    count = distanceTwoPoint(fromPoint,controlPoint1) + distanceTwoPoint(controlPoint1,controlPoint2) + distanceTwoPoint(controlPoint2,toPoint);
    for (double t = 0.0; t <= count; t++) {
        if(vertexCount == _vertexMax) {
            _vertexMax = 2 * _vertexMax;
            _vertexBuffer = realloc(_vertexBuffer, _vertexMax * 2 * sizeof(GLfloat));
        }
        
        CGPoint point = bezierPath(fromPoint, controlPoint1, controlPoint2, toPoint, t / count);
        
        _vertexBuffer[2 * vertexCount + 0] = point.x;
        _vertexBuffer[2 * vertexCount + 1] = point.y;
        [_pointArray addObject:NSStringFromCGPoint(point)];
        
        vertexCount ++;
    }
    
    [self renderLineFromVertexBuffer:_vertexBuffer vertexCount:vertexCount];
    [self presentRenderbuffer];
}
//两点之间的距离
static uint distanceTwoPoint(CGPoint fromPoint, CGPoint toPoint)
{
    uint distance = ceil(sqrt((fromPoint.x-toPoint.x)*(fromPoint.x-toPoint.x) + (fromPoint.y-toPoint.y)*(fromPoint.y-toPoint.y)));
    return distance;
}
//三阶贝塞尔曲线
static CGPoint bezierPath(CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4,double t) {
    CGPoint p;
    double a1 = (1 - t) * (1 - t) * (1 - t);
    double a2 = (1 - t) * (1 - t) * 3 * t;
    double a3 = 3 * t*t*(1 - t);
    double a4 = t*t*t;
    p.x = a1*p1.x + a2*p2.x + a3*p3.x + a4*p4.x;
    p.y = a1*p1.y + a2*p2.y + a3*p3.y + a4*p4.y;
    return p;
}
#pragma mark - Setter / Getter
- (NSMutableArray *)lineArray
{
    if (!_lineArray) {
        _lineArray = [NSMutableArray array];
    }
    return _lineArray;
}
- (NSMutableArray *)deletedLineArray
{
    if (!_deletedLineArray) {
        _deletedLineArray = [NSMutableArray array];
    }
    return _deletedLineArray;
}
@end
