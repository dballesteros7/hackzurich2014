/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <QCAR/QCAR.h>
#import <QCAR/State.h>
#import <QCAR/Tool.h>
#import <QCAR/Renderer.h>
#import <QCAR/VideoBackgroundConfig.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/ImageTargetResult.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/ImageTracker.h>
#import <QCAR/TargetFinder.h>

#import "CloudRecoEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"
#import "Quad.h"
#import "CloudRecoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the QCAR camera, which causes QCAR to locate our EAGLView and start
//    the render thread.
// 3) QCAR calls our renderFrameQCAR method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************



namespace {
    // --- Data private to this unit ---
    
    // Teapot texture filenames
    const char* postText[] = {
        "Stop staring, finish the code!",
        "Checkout the other booths!",
    };
    
    // Model scale factor
    const float kObjectScale = 3.0f;
}

@implementation Object3D

@synthesize numVertices;
@synthesize vertices;
@synthesize normals;
@synthesize texCoords;
@synthesize numIndices;
@synthesize indices;
@synthesize texture;

@end

@interface CloudRecoEAGLView ()

@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) NSString *currentUrl;
@property (nonatomic) BOOL newImageAvailable;
@property (nonatomic) BOOL imageScanned;
@property (nonatomic) BOOL hasImageView;
@property (nonatomic, strong) UIImageView *currentImageView;

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end


@implementation CloudRecoEAGLView

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame  appSession:(SampleApplicationSession *) app viewController:(CloudRecoViewController *) aViewController
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        viewController = aViewController;
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panRecognizer];
        
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self addGestureRecognizer:pinchRecognizer];

        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:2.0f];
        }
        
        // Load the augmentation textures
        
        for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            UIImage *uiImage = [self drawText:[NSString stringWithUTF8String:postText[i]] inImage:@"white.png" atPoint:CGPointMake(10,10)];
            self.currentImage = uiImage;
            
            augmentationTexture[i] = [[Texture alloc] initWithUIImage:uiImage];
        }
        
        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation
        for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [augmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
        }
        
        offTargetTrackingEnabled = NO;

        [self initShaders];
    }
    
    return self;
}

- (UIImageView *)currentImageView {
    if(!_currentImageView) {
        _currentImageView = [[UIImageView alloc]initWithImage:self.currentImage];
    }
    return _currentImageView;
}

- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
    
    for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
        [augmentationTexture[i] release];
    }
    
    [super dealloc];
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

- (void) setOffTargetTrackingMode:(BOOL) enabled {
    offTargetTrackingEnabled = enabled;
}

-(IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self];
    CGPoint location = [recognizer locationInView:self];
    for (UIView *subview in self.subviews) {
        if (location.x >= subview.frame.origin.x && location.x <= subview.frame.origin.x+subview.frame.size.width && location.y >= subview.frame.origin.y && location.y <= subview.frame.origin.y+subview.frame.size.height) {
            subview.center = CGPointMake(subview.center.x+translation.x, subview.center.y+translation.y);
        }
    }
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:self];
    
}

-(IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {

    for (UIView *subview in self.subviews) {
        CGPoint center = subview.center;
        subview.frame = CGRectMake(subview.frame.origin.x, subview.frame.origin.y,subview.frame.size.width*recognizer.scale, subview.frame.size.height*recognizer.scale);
        subview.center = center;
    }
    recognizer.scale = 1.0f;
}



//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method periodically on a background thread ***
- (void)renderFrameQCAR
{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const QCAR::TrackableResult* result = state.getTrackableResult(i);
        const QCAR::Trackable & trackable = result->getTrackable ();
        QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        
        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
        //        NSString *newNote = [self getNoteWithId:trackable.getName()];
//        NSString * newUrl = @"http://i.imgur.com/pvKqkHO.jpg";
//        if (self.currentUrl != newUrl) {
//            self.currentUrl = newUrl;
//            self.newImageAvailable = true;
//            
//        }
//        if (self.newImageAvailable){
//            [self getUIImageWithUrl:self.currentUrl];
//        }
        
        // OpenGL 2
        QCAR::Matrix44F modelViewProjection;
        
        SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScale, &modelViewMatrix.data[0]);
        SampleApplicationUtils::scalePoseMatrix(kObjectScale, kObjectScale, kObjectScale, &modelViewMatrix.data[0]);
        SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
        
        glUseProgram(shaderProgramID);
        
        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadVertices);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadNormals);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadTexCoords);
        
        glEnableVertexAttribArray(vertexHandle);
        glEnableVertexAttribArray(normalHandle);
        glEnableVertexAttribArray(textureCoordHandle);
        
        glActiveTexture(GL_TEXTURE0);
        int targetIndex = 0; // "stones"
        if (!strcmp(trackable.getName(), "Screen"))
            targetIndex = 1;
        else if (!strcmp(trackable.getName(), "Poster"))
            targetIndex = 2;

        @synchronized(self) {
            glBindTexture(GL_TEXTURE_2D, augmentationTexture[0].textureID);
        }
        glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
        glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
        glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
        
        SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
        
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    glDisableVertexAttribArray(vertexHandle);
    glDisableVertexAttribArray(normalHandle);
    glDisableVertexAttribArray(textureCoordHandle);
    
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];
    
    if (state.getNumTrackableResults() > 0) {
        self.imageScanned = true;
        // we have a trackable so we stop the finder if it was on
        if ([viewController isVisualSearchOn]) {
            [viewController toggleVisualSearch];
        }
        if (self.hasImageView) {
            self.hasImageView = false;
            dispatch_async(dispatch_get_main_queue(), ^{
//            [UIView animateWithDuration:0.5f
//                                  delay:0.0f
//                                options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
//                             animations:^{
//                                 self.currentImageView.frame = CGRectMake(self.frame.size.width/2, -self.frame.size.height/2, self.currentImageView.frame.size.width/3, self.currentImageView.frame.size.height/3);
//                             }
//                             completion:^(BOOL finished){
//                             }];
            });
        }
    } else {
        
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // we have a no trackable so we retsrat the finder if not already started
        if (self.imageScanned && !self.hasImageView) {
            dispatch_async(dispatch_get_main_queue(), ^ {
            self.hasImageView = true;
            self.currentImageView.frame = CGRectMake(-self.frame.size.width/2, self.frame.size.height*1/2, self.currentImage.size.width/4, self.currentImage.size.height/4);
            [self addSubview:self.currentImageView];
            
            [UIView animateWithDuration:0.8f
                                  delay:0.1f
                                options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.currentImageView.frame = CGRectMake(self.frame.size.width/10, self.frame.size.height/10, self.currentImage.size.width/2, self.currentImage.size.height/2);
                             }
                             completion:nil];
            });
        }
        if (! [viewController isVisualSearchOn]) {
            [viewController toggleVisualSearch];
        }
    }
    
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(UIImage*) drawText:(NSString*) text
             inImage:(NSString*)  imageName
             atPoint:(CGPoint)   point
{
    
    NSString* imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    UIFont *font = [UIFont boldSystemFontOfSize:35];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor blackColor] set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSString *) getNoteWithId:(const char*) noteId {
    NSString* NSID = [NSString stringWithUTF8String:noteId];    
    return @"lalalala";
}

- (void) getUIImageWithUrl:(NSString *) noteUrl {
    NSURL *url = [NSURL URLWithString:noteUrl];
    dispatch_queue_t fetchQ = dispatch_queue_create("fetch note", NULL);
    dispatch_async(fetchQ, ^{
        self.newImageAvailable = false;
        NSData *photo = [[NSData alloc] initWithContentsOfURL:url];
        dispatch_sync(dispatch_get_main_queue(), ^{
            @synchronized(self) {
                self.currentImage = [UIImage imageWithData:photo];
                [augmentationTexture[0] dealloc];
                augmentationTexture[0] = [[Texture alloc]initWithUIImage:self.currentImage];
                GLuint textureID;
                glGenTextures(1, &textureID);
                [augmentationTexture[0] setTextureID:textureID];
                glBindTexture(GL_TEXTURE_2D, textureID);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[0] width], [augmentationTexture[0] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[0] pngData]);
                
                
                glActiveTexture(GL_TEXTURE0);
            }
        });
        [photo release];
    });
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                   fragmentShaderFileName:@"Simple.fragsh"];
    
    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}



@end
