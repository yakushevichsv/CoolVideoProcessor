//
//  LogoViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/15/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "LogoViewController.h"

@interface LogoViewController()

@property (nonatomic,strong) EAGLContext * context;
@property (nonatomic,strong) GLKBaseEffect * effect;
@property (nonatomic) GLuint bufferId;
@end

#define LIMITED_EDITION_DELAY 6

typedef struct {
    GLKVector3  positionCoords;
}
SceneVertex;

static SceneVertex points[] = {{0.5,0.0,0.0},
                            {0.0,0.5,0.0},
                            {-0.5,0.0,0.0}};

@implementation LogoViewController

-(GLKView*)glkView
{
    return (GLKView*)self.view;
}

-(BOOL)fullVersion
{
    return TRUE;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self fullVersion])
    {
        [self execSeque];
        return ;
    }
    else
    {
        [self performSelector:@selector(execSeque) withObject:nil afterDelay:LIMITED_EDITION_DELAY];
    }
    
    self.preferredFramesPerSecond = 30;
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    [EAGLContext setCurrentContext:self.context];
    
    self.glkView.context =self.context;
    
    self.effect = [GLKBaseEffect new];
    
    self.effect.useConstantColor = TRUE;
    self.effect.constantColor = GLKVector4Make(1, 0, 0, 1.0);
    
    glClearColor(0, 0, 0, 1);
    
    [self setupBuffers];
 
    GLKMatrix4 modelviewMatrix = GLKMatrix4MakeRotation(
                                                        GLKMathDegreesToRadians(30.0f),
                                                        1.0,  // Rotate about X axis
                                                        0.0,
                                                        0.0);
    modelviewMatrix = GLKMatrix4Rotate(
                                       modelviewMatrix,
                                       GLKMathDegreesToRadians(-30.0f),
                                       0.0,  
                                       1.0,  // Rotate about Y axis
                                       0.0);
    modelviewMatrix = GLKMatrix4Translate(
                                          modelviewMatrix,
                                          -0.25, 
                                          0.25,
                                          -0.20);
    
    self.effect.transform.modelviewMatrix = modelviewMatrix;
}

-(void)setupBuffers
{
    glGenBuffers(1,&_bufferId);
    
    glBindBuffer(GL_ARRAY_BUFFER, _bufferId);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    self.effect.transform.modelviewMatrix=GLKMatrix4RotateY(self.effect.transform.modelviewMatrix, GLKMathDegreesToRadians(1));
     [self.effect prepareToDraw];    //[self.baseEffect prepareToDraw];
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    glBindBuffer(GL_ARRAY_BUFFER,     // STEP 2
                 _bufferId);
    
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    
    glVertexAttribPointer(            // Step 5
                          GLKVertexAttribPosition,               // Identifies the attribute to use
                          3,               // number of coordinates for attribute
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          (3 * sizeof(GLfloat)),         // total num bytes stored per vertex
                          NULL+offsetof(SceneVertex, positionCoords));      // offset from start of each vertex to
    // first coord for attribute
#ifdef DEBUG
    {  // Report any errors
        GLenum error = glGetError();
        if(GL_NO_ERROR != error)
        {
            NSLog(@"GL Error: 0x%x", error);
        }
    }
#endif
    
    
    glDrawArrays(GL_TRIANGLES, 0, sizeof(points) / sizeof(SceneVertex));
    
    
}

-(void)resetContext
{
    if (self.context && [EAGLContext currentContext] ==self.context)
    {
        [EAGLContext setCurrentContext:nil];
        self.context = nil;
    }
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    
    [self cleanup];
    
}

-(void) cleanup
{
    [EAGLContext setCurrentContext:self.context];
    
    if (0 != self.bufferId)
    {
        glDeleteBuffers (1, _bufferId);
        self.bufferId = 0;
    }
    
    [self resetContext];
}

-(void) dealloc
{
    [self cleanup];
}

-(void)execSeque
{
    if (!self.isViewLoaded)
    {
        [self performSelector:@selector(execSeque) withObject:nil afterDelay:1];
    }
    else
        [self performSegueWithIdentifier:@"firstManualSeque" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"firstManualSeque"])
    {
        if ([sender isKindOfClass:[GLKViewController class]])
        {
            GLKViewController * controller = (GLKViewController*)sender;
            NSInteger framesCount = controller.framesDisplayed;
            NSLog(@"Frames count : %d , aprox time: %f. Timer was scheduled after %d",framesCount,((CGFloat)framesCount)/controller.framesPerSecond,LIMITED_EDITION_DELAY);
        }
    }
}

@end
