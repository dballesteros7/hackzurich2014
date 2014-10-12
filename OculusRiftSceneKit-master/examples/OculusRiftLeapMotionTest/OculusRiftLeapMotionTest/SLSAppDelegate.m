//
//  SLSAppDelegate.m
//  OculusRiftLeapMotionTest
//
//  Created by Brad Larson on 8/14/2013.
//  Copyright (c) 2013 Sunset Lake Software LLC. All rights reserved.
//

#import "SLSAppDelegate.h"
#import "GestureListener.h"
#import "Gesture.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CGDirectDisplay.h>
#import "evernote_wrapper.h"
#import <GLUT/GLUT.h>


@interface SLSAppDelegate ()
{
    AVCaptureSession *session;
    dispatch_queue_t sessionQueue;
}
@end

@implementation SLSAppDelegate

#pragma mark -
#pragma mark Initialization and teardown

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupSceneRendering];
    [self setupHandRendering];
    
    // Have this start in fullscreen so that the rendering matches up to the Oculus Rift
    [self.window toggleFullScreen:nil];

    // Initialize Leap Motion controls
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    [self.window makeKeyAndOrderFront:nil];
}

- (void)setupSceneRendering;    //The scene
{
    SCNScene *scene = [SCNScene scene];
    
    SCNNode *objectsNode = [SCNNode node];
    [scene.rootNode addChildNode:objectsNode];
    
    
    CGFloat roomRadius = 600.0;
    
    // Set up the object and wall materials
    SCNMaterial *holodeckWalls = [SCNMaterial material];
    holodeckWalls.diffuse.minificationFilter = SCNLinearFiltering;
    holodeckWalls.diffuse.magnificationFilter = SCNLinearFiltering;
    holodeckWalls.diffuse.mipFilter = SCNLinearFiltering;
    NSImage *diffuseImage = [NSImage imageNamed:@"Holodeck"];
    holodeckWalls.diffuse.contents  = diffuseImage;
//    holodeckWalls.diffuse.wrapS = SCNWrapModeRepeat;
//    holodeckWalls.diffuse.wrapT = SCNWrapModeRepeat;
    holodeckWalls.specular.contents = [NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    holodeckWalls.shininess = 0.25;
    
    SCNMaterial *torusReflectiveMaterial = [SCNMaterial material];
    torusReflectiveMaterial.diffuse.contents = [NSColor blueColor];
    torusReflectiveMaterial.specular.contents = [NSColor whiteColor];
    torusReflectiveMaterial.shininess = 100.0;
    
    // Configure the room
    
    SCNPlane *floor = [SCNPlane planeWithWidth:roomRadius * 2.0 height:roomRadius * 2.0];
    floor.materials = @[holodeckWalls];
    SCNNode *floorNode = [SCNNode nodeWithGeometry:floor];
    CATransform3D wallTransform = CATransform3DMakeTranslation(0.0, -roomRadius, 0.0);
    wallTransform = CATransform3DRotate(wallTransform, -M_PI /2.0, 1.0, 0.0, 0.0);
    floorNode.transform = wallTransform;
    [scene.rootNode addChildNode:floorNode];
    
    SCNPlane *ceiling = [SCNPlane planeWithWidth:roomRadius * 2.0 height:roomRadius * 2.0];
    ceiling.materials = @[holodeckWalls];
    SCNNode *ceilingNode = [SCNNode nodeWithGeometry:ceiling];
    wallTransform = CATransform3DMakeTranslation(0.0, roomRadius, 0.0);
    wallTransform = CATransform3DRotate(wallTransform, M_PI /2.0, 1.0, 0.0, 0.0);
    ceilingNode.transform = wallTransform;
    [scene.rootNode addChildNode:ceilingNode];
    
    SCNPlane *leftWall = [SCNPlane planeWithWidth:roomRadius * 2.0 height:roomRadius * 2.0];
    leftWall.materials = @[holodeckWalls];
    SCNNode *leftWallNode = [SCNNode nodeWithGeometry:leftWall];
    wallTransform = CATransform3DMakeTranslation(-roomRadius, 0.0, 0.0);
    wallTransform = CATransform3DRotate(wallTransform, M_PI /2.0, 0.0, 1.0, 0.0);
    leftWallNode.transform = wallTransform;
    [scene.rootNode addChildNode:leftWallNode];
    
    SCNPlane *rightWall = [SCNPlane planeWithWidth:roomRadius * 2.0 height:roomRadius * 2.0];
    rightWall.materials = @[holodeckWalls];
    SCNNode *rightWallNode = [SCNNode nodeWithGeometry:rightWall];
    wallTransform = CATransform3DMakeTranslation(roomRadius, 0.0, 0.0);
    wallTransform = CATransform3DRotate(wallTransform, -M_PI /2.0, 0.0, 1.0, 0.0);
    rightWallNode.transform = wallTransform;
    [scene.rootNode addChildNode:rightWallNode];
    
    SCNPlane *frontWall = [SCNPlane planeWithWidth:roomRadius * 2.0 height:roomRadius * 2.0];
    frontWall.materials = @[holodeckWalls];
    SCNNode *frontWallNode = [SCNNode nodeWithGeometry:frontWall];
    wallTransform = CATransform3DMakeTranslation(0.0, 0.0, -roomRadius);
    frontWallNode.transform = wallTransform;
    [scene.rootNode addChildNode:frontWallNode];
    
    SCNPlane *rearWall = [SCNPlane planeWithWidth:roomRadius * 2.0 height:roomRadius * 2.0];
    rearWall.materials = @[holodeckWalls];
    SCNNode *rearWallNode = [SCNNode nodeWithGeometry:rearWall];
    wallTransform = CATransform3DMakeTranslation(0.0, 0.0, roomRadius);
    wallTransform = CATransform3DRotate(wallTransform, -M_PI, 0.0, 1.0, 0.0);
    rearWallNode.transform = wallTransform;
    [scene.rootNode addChildNode:rearWallNode];
    
    // Throw a few objects into the room
    //const char* note=getNotes();  //TO HACK
    const char* note="Hello";
    //TODO
    NSString* string = [NSString stringWithUTF8String:note];
    
    SCNText *text = [SCNText textWithString:string extrusionDepth:1.0f];
    SCNNode *textNode = [SCNNode nodeWithGeometry:text];
    textNode.position = SCNVector3Make(200, 0, -100);
    [objectsNode addChildNode:textNode];
    
    SCNBox *cube = [SCNBox boxWithWidth:200 height:200 length:200 chamferRadius:0.0];
    SCNNode *cubeNode = [SCNNode nodeWithGeometry:cube];
    cubeNode.position = SCNVector3Make(300, 0, -300);
    [objectsNode addChildNode:cubeNode];
    
    SCNTorus *torus = [SCNTorus torusWithRingRadius:60 pipeRadius:20];
    SCNNode *torusNode = [SCNNode nodeWithGeometry:torus];
    torusNode.position = SCNVector3Make(-50, 0, -200);
    torus.materials = @[torusReflectiveMaterial];
    [objectsNode addChildNode:torusNode];
    
    SCNCylinder *cylinder = [SCNCylinder cylinderWithRadius:40.0 height:100.0];
    SCNNode *cylinderNode = [SCNNode nodeWithGeometry:cylinder];
    cylinderNode.position = SCNVector3Make(-400, -400, -400);
    [objectsNode addChildNode:cylinderNode];
    
    SCNSphere *sphere = [SCNSphere sphereWithRadius:40.0];
    SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
    sphereNode.position = SCNVector3Make(200, -200, 0);
    [objectsNode addChildNode:sphereNode];
    
    SCNPyramid *pyramid = [SCNPyramid pyramidWithWidth:60 height:60 length:60];
    SCNNode *pyramidNode = [SCNNode nodeWithGeometry:pyramid];
    pyramidNode.position = SCNVector3Make(200, 200, -200);
    [objectsNode addChildNode:pyramidNode];
    
    

    // Create ambient light
//    SCNLight *ambientLight = [SCNLight light];
//	SCNNode *ambientLightNode = [SCNNode node];
//    ambientLight.type = SCNLightTypeAmbient;
//	ambientLight.color = [NSColor colorWithDeviceWhite:0.1 alpha:1.0];
//	ambientLightNode.light = ambientLight;
//    [scene.rootNode addChildNode:ambientLightNode];
    
    // Create a diffuse light
//	SCNLight *diffuseLight = [SCNLight light];
//    SCNNode *diffuseLightNode = [SCNNode node];
//    diffuseLight.type = SCNLightTypeOmni;
//	diffuseLight.color = [NSColor colorWithDeviceWhite:0.2 alpha:1.0];
//    diffuseLightNode.light = diffuseLight;
//	diffuseLightNode.position = SCNVector3Make(0, 300, 0);
//	[scene.rootNode addChildNode:diffuseLightNode];
    
    // Animate the objects
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.values = [NSArray arrayWithObjects:
                        [NSValue valueWithCATransform3D:CATransform3DRotate(torusNode.transform, 0 * M_PI / 2, 1.f, 0.5f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(torusNode.transform, 1 * M_PI / 2, 1.f, 0.5f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(torusNode.transform, 2 * M_PI / 2, 1.f, 0.5f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(torusNode.transform, 3 * M_PI / 2, 1.f, 0.5f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(torusNode.transform, 4 * M_PI / 2, 1.f, 0.5f, 0.f)],
                        nil];
    animation.duration = 3.f;
    animation.repeatCount = HUGE_VALF;
    
    CAKeyframeAnimation *animation2 = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation2.values = [NSArray arrayWithObjects:
                         [NSValue valueWithCATransform3D:CATransform3DRotate(cubeNode.transform, 0 * M_PI / 2, 1.f, 0.5f, 0.f)],
                         [NSValue valueWithCATransform3D:CATransform3DRotate(cubeNode.transform, 1 * M_PI / 2, 1.f, 0.5f, 0.f)],
                         [NSValue valueWithCATransform3D:CATransform3DRotate(cubeNode.transform, 2 * M_PI / 2, 1.f, 0.5f, 0.f)],
                         [NSValue valueWithCATransform3D:CATransform3DRotate(cubeNode.transform, 3 * M_PI / 2, 1.f, 0.5f, 0.f)],
                         [NSValue valueWithCATransform3D:CATransform3DRotate(cubeNode.transform, 4 * M_PI / 2, 1.f, 0.5f, 0.f)],
                         nil];
    animation2.duration = 7.f;
    animation2.repeatCount = HUGE_VALF;
    
    
    [torusNode addAnimation:animation forKey:@"transform"];
    [cubeNode addAnimation:animation2 forKey:@"transform"];
    
    self.oculusView.scene = scene;
}

- (void)setupHandRendering;
{
    // This will need to be adjusted for the relative position of the controller to the Rift
    leapMotionControllerPosition.x = 0.0;
    leapMotionControllerPosition.y = -400.0;
    leapMotionControllerPosition.z = -200.0;
    leapMotionToVirtualWorldScalingFactor = 1.5;
    
    SCNMaterial *handMaterial = [SCNMaterial material];
    handMaterial.diffuse.contents = [NSColor colorWithDeviceRed:0.38 green:0.70 blue:0.76 alpha:1.0];
    handMaterial.emission.contents = [NSColor colorWithDeviceRed:0.38 green:0.70 blue:0.76 alpha:1.0];
    handMaterial.emission.intensity = 0.5;

    
    /* begin draw line*/
    //Hack Add track points
    NSLog(@"render line");
    
    NSLog(@"current finger position: %f, %f, %f", currFingerPosition.x, currFingerPosition.y, currFingerPosition.z);
    NSLog(@"prev finger position: %f, %f, %f", prevFingerPosition.x, prevFingerPosition.y, prevFingerPosition.z);
    

    SCNVector3 positions[] = {
        SCNVector3Make(0.0,0.0,0.0),
        SCNVector3Make(1.0,0.0,0.0),
    };
    
    int indices[] = {0, 1};
    
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    
    lineNode = [SCNNode nodeWithGeometry:line];
    SCNMaterial *lineMaterial = [SCNMaterial material];
    lineMaterial.diffuse.contents = [NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    lineMaterial.emission.contents = [NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    lineMaterial.emission.intensity = 0.5;

    //line.materials = @[lineMaterial];
    [self.oculusView.scene.rootNode addChildNode:lineNode];
    
    /*
    SCNVector3 positions2[] = {
        SCNVector3Make(0.0, 0.0, 0.0),
        SCNVector3Make(100.0, 0.0, 0.0),
        SCNVector3Make(100.0, 0.0, 100.0)
    };
    
    int indices2[] = {0, 1,2};
    
    SCNGeometrySource *vertexSource2 = [SCNGeometrySource geometrySourceWithVertices:positions2
                                                                              count:3];
    
    NSData *indexData2 = [NSData dataWithBytes:indices2
                                       length:sizeof(indices2)];
    
    SCNGeometryElement *element2 = [SCNGeometryElement geometryElementWithData:indexData2
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:2
                                                                bytesPerIndex:sizeof(int)];
    
    SCNGeometry *line2 = [SCNGeometry geometryWithSources:@[vertexSource2]
                                                elements:@[element2]];
    
    lineNode2 = [SCNNode nodeWithGeometry:line2];
    [self.oculusView.scene.rootNode addChildNode:lineNode2];
    */
    /*
    SCNVector3 positions[] = {
        SCNVector3Make(prevFingerPosition.x, prevFingerPosition.y, prevFingerPosition.z),
        SCNVector3Make(currFingerPosition.x,currFingerPosition.y,currFingerPosition.z)
    };
    prevFingerPosition = currFingerPosition;
    
    int indices[] = {0, 1};
    
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    
    SCNNode *lineNode = [SCNNode nodeWithGeometry:line];
    
    [self.oculusView.scene.rootNode addChildNode:lineNode];
    */
    /*end draw line*/
    
    
   
//    handMaterial.specular.contents = [NSColor whiteColor];
//    handMaterial.shininess = 20.0;
    
    SCNSphere *handSphere = [SCNSphere sphereWithRadius:30.0];
    handSphere.materials = @[handMaterial];

    firstHandNode = [SCNNode nodeWithGeometry:handSphere];
    firstHandNode.opacity = 0.0;
    [self.oculusView.scene.rootNode addChildNode:firstHandNode];

    secondHandNode = [SCNNode nodeWithGeometry:handSphere];
    secondHandNode.opacity = 0.0;
    [self.oculusView.scene.rootNode addChildNode:secondHandNode];
    
    firstHandFingerNodes = [[NSMutableArray alloc] init];
    secondHandFingerNodes = [[NSMutableArray alloc] init];

    for (unsigned int currentFinger = 0; currentFinger < 5; currentFinger++)
    {
        SCNBox *fingerBox = [SCNBox boxWithWidth:10 height:10 length:30 chamferRadius:0.0];
        fingerBox.materials = @[handMaterial];
        SCNNode *fingerNode = [SCNNode nodeWithGeometry:fingerBox];
        fingerNode.opacity = 0.0;
        [firstHandFingerNodes addObject:fingerNode];
        [self.oculusView.scene.rootNode addChildNode:fingerNode];

        fingerBox = [SCNBox boxWithWidth:10 height:10 length:30 chamferRadius:0.0];
        fingerBox.materials = @[handMaterial];
        fingerNode = [SCNNode nodeWithGeometry:fingerBox];
        fingerNode.opacity = 0.0;
        [secondHandFingerNodes addObject:fingerNode];
        [self.oculusView.scene.rootNode addChildNode:fingerNode];
    }

    // Add a light source, centered on the hands
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.color = [NSColor colorWithDeviceRed:0.38 green:0.70 blue:0.76 alpha:1.0];
    lightNode.light.type = SCNLightTypeOmni;
    [lightNode.light setAttribute:@800 forKey:SCNLightAttenuationEndKey];
    [lightNode.light setAttribute:@100 forKey:SCNLightAttenuationStartKey];

    [firstHandNode addChildNode:lightNode];

    SCNNode *lightNode2 = [SCNNode node];
    lightNode2.light = [SCNLight light];
    lightNode2.light.color = [NSColor colorWithDeviceRed:0.38 green:0.70 blue:0.76 alpha:1.0];
    lightNode2.light.type = SCNLightTypeOmni;
    [lightNode2.light setAttribute:@800 forKey:SCNLightAttenuationEndKey];
    [lightNode2.light setAttribute:@100 forKey:SCNLightAttenuationStartKey];
    
    [secondHandNode addChildNode:lightNode2];
    
    
}

- (void)moveFingers:(NSMutableArray *)fingerNodes andHand:(SCNNode *)handNode toMatchLeapHand:(LeapHand *)leapHand; //SPOT::Here is the coordinate sys of the hands.
{
    LeapVector *handPosition = leapHand.palmPosition;
    handNode.opacity = 1.0;
    /*
    handNode.position = SCNVector3Make(handPosition.x * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.x, handPosition.y * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.y, handPosition.z * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.z);
    */
    handNode.position = SCNVector3Make(handPosition.x * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.x, handPosition.y * leapMotionToVirtualWorldScalingFactor - leapMotionControllerPosition.z, handPosition.z * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.y);
    NSUInteger numberOfFingers = MIN([[leapHand fingers] count], 5);
    for (NSUInteger currentFingerIndex = 0; currentFingerIndex < numberOfFingers; currentFingerIndex++)
    {
        SCNNode *currentFingerNode = [fingerNodes objectAtIndex:currentFingerIndex];
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.35];
        currentFingerNode.opacity = 1.0;
        [SCNTransaction commit];
        
        LeapFinger *currentFinger = [[leapHand fingers] objectAtIndex:currentFingerIndex];
        LeapVector *fingerPosition = currentFinger.tipPosition;
        /*
        currentFingerNode.position = SCNVector3Make(fingerPosition.x * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.x, fingerPosition.y * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.y, fingerPosition.z * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.z);
         */
        currentFingerNode.position = SCNVector3Make(fingerPosition.x * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.x, fingerPosition.y * leapMotionToVirtualWorldScalingFactor - leapMotionControllerPosition.z, fingerPosition.z * leapMotionToVirtualWorldScalingFactor + leapMotionControllerPosition.y);
    }
    
    if (numberOfFingers < 5)
    {
        for (NSUInteger currentInvisibleFingerIndex = numberOfFingers; currentInvisibleFingerIndex < 5; currentInvisibleFingerIndex++)
        {
            SCNNode *currentFingerNode = [fingerNodes objectAtIndex:currentInvisibleFingerIndex];
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.35];
            currentFingerNode.opacity = 0.0;
            [SCNTransaction commit];
        }
    }
    
    if (1) {   //TOHACK
        //SCNNode *currentFingerNode = [fingerNodes objectAtIndex:1]; //Indexfinger hack
        LeapFinger *currentFinger = [[leapHand fingers] objectAtIndex:1];
        LeapVector *fingerPosition = currentFinger.tipPosition;
        currFingerPosition = fingerPosition;
        //Store the tipPosition to array or vector.
        //trackPointPositions[trackPointPositionIndex]=SCNVector3Make(fingerPosition.x, fingerPosition.y, fingerPosition.z);  //Dirty Hack
        //trackPointPositionIndex++;  //Dirty Hack
        [trackPoints addObject:fingerPosition];
        /*
         NSBeep();
        NSLog(@"New point added (%f,%f,%f)",fingerPosition.x,fingerPosition.y,fingerPosition.z);
        NSLog(@"New point added (%@)",fingerPosition);
        NSLog(@"New point added (%@),%p",trackPoints,trackPoints);
         */
        //Hack Add track points
        //SCNScene *scene = [SCNScene scene];
        
        //SCNNode *objectsNode = [SCNNode node];
        //[scene.rootNode addChildNode:objectsNode];
        
        /*
        NSLog(@"render line onFrame");
        SCNVector3 positions[] = {
            SCNVector3Make(prevFingerPosition.x,prevFingerPosition.y, prevFingerPosition.z),
            SCNVector3Make(fingerPosition.x, fingerPosition.y,fingerPosition.z)
        };
        
        int indices[] = {0, 1};
        
        SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                                  count:2];
        
        NSData *indexData = [NSData dataWithBytes:indices
                                           length:sizeof(indices)];
        
        SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                    primitiveType:SCNGeometryPrimitiveTypeLine
                                                                   primitiveCount:1
                                                                    bytesPerIndex:sizeof(int)];
        
        SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                    elements:@[element]];
        
        SCNNode *lineNode = [SCNNode nodeWithGeometry:line];
        
        //[currentFinger addChildNode:lineNode];
        prevFingerPosition=fingerPosition;
         */
    }



}

#pragma mark -
#pragma mark Rendering adjustments

- (IBAction)increaseIPD:(id)sender;
{
    self.oculusView.interpupillaryDistance = self.oculusView.interpupillaryDistance + 2.0;
}

- (IBAction)decreaseIPD:(id)sender;
{
    self.oculusView.interpupillaryDistance = self.oculusView.interpupillaryDistance - 2.0;
}

- (IBAction)increaseDistance:(id)sender;
{
    SCNVector3 currentLocation = self.oculusView.headLocation;
    currentLocation.z = currentLocation.z - 50.0;
    self.oculusView.headLocation = currentLocation;
}

- (IBAction)decreaseDistance:(id)sender;
{
    SCNVector3 currentLocation = self.oculusView.headLocation;
    currentLocation.z = currentLocation.z + 50.0;
    self.oculusView.headLocation = currentLocation;
}

#pragma mark -
#pragma mark Leap Motion callbacks

- (void)onInit:(NSNotification *)notification
{
    NSLog(@"Leap init");
}

- (void)onConnect:(NSNotification *)notification;
{
    [controller enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES]; //CK
    [controller enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES]; //CK
    [controller enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES]; //CK
    [controller enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES]; //CK
    trackPoints = [[NSMutableArray alloc] init];
    //[trackPoints addObject:(0.0,0.0,0.0)];
    //[trackPoints addObject:(0,0,1)];
    
    positionStart=SCNVector3Make(0.0, 0.0, 0.0);
    positionEnd=SCNVector3Make(0.0, 0.0, 0.0);
    drawLineFlag=false;
    
    prevFingerPosition = (0,0,0);
    currFingerPosition = (0,0,0);
    NSLog(@"Leap connect");
}

- (void)onDisconnect:(NSNotification *)notification;
{
    NSLog(@"Leap disconnect");
}

- (void)onExit:(NSNotification *)notification;
{
    NSLog(@"Leap exit");
}

- (void)onFrame:(NSNotification *)notification;
{
    
    
    //renderTrack.render();
    LeapController *aController = (LeapController *)[notification object];
    
    // Get the most recent frame and report some basic information
    LeapFrame *currentLeapFrame = [aController frame:0];
    NSUInteger indexOfCurrentHand = 0;
    for (LeapHand *currentHand in [currentLeapFrame hands])
    {
        if (indexOfCurrentHand == 0)
        {
         //   NSLog(@"Process hand one");
            [self moveFingers:firstHandFingerNodes andHand:firstHandNode toMatchLeapHand:currentHand];
            //firstHandNode.position.x
        }
        else if (indexOfCurrentHand == 1)
        {
            //NSLog(@"Process hand two");
            [self moveFingers:secondHandFingerNodes andHand:secondHandNode toMatchLeapHand:currentHand];
        }
        
        indexOfCurrentHand++;
    }
    
    //HACK::BEG LeapGesture
    NSArray *gestures = [currentLeapFrame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        if(gesture.state != LEAP_GESTURE_STATE_STOP){
            return;
        }
        switch (gesture.type) {
            case LEAP_GESTURE_TYPE_CIRCLE: {
                NSBeep();
                LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;
                // Calculate the angle swept since the last frame
                float sweptAngle = 0;
                if(circleGesture.state != LEAP_GESTURE_STATE_START) {
                    LeapCircleGesture *previousUpdate = (LeapCircleGesture *)[[aController frame:1] gesture:gesture.id];
                    sweptAngle = (circleGesture.progress - previousUpdate.progress) * 2 * LEAP_PI;
                }
                
                NSLog(@"Circle id: %d, progress: %f, radius %f, angle: %f degrees",
                   circleGesture.id, circleGesture.progress, circleGesture.radius, sweptAngle * LEAP_RAD_TO_DEG);
                break;
            }
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
                NSLog(@"Swipe id: %d,  position: %@, direction: %@, speed: %f",
                      swipeGesture.id,                       swipeGesture.position, swipeGesture.direction, swipeGesture.speed);
                if ( 1 ) // good gesture
                {
                    [self takeScreenShot];
                }
                break;
            }
            case LEAP_GESTURE_TYPE_KEY_TAP: {
                LeapKeyTapGesture *keyTapGesture = (LeapKeyTapGesture *)gesture;
                NSBeep();
                NSLog(@"Key Tap id: %d, position: %@, direction: %@",
                    keyTapGesture.id,keyTapGesture.position, keyTapGesture.direction);
                if(drawLineFlag==false){
                    NSLog(@"Get the start position");
                    positionStart=SCNVector3Make(keyTapGesture.position.x,keyTapGesture.position.y,keyTapGesture.position.z);
                    drawLineFlag=true;
                }
                else{
                    NSLog(@"Get the end Position and change");
                    positionEnd=SCNVector3Make(keyTapGesture.position.x, keyTapGesture.position.y, keyTapGesture.position.z);
                    [self changeSettings];
                    drawLineFlag=false;
                }
                break;
            }
            case LEAP_GESTURE_TYPE_SCREEN_TAP: {
                NSBeep();
                LeapScreenTapGesture *screenTapGesture = (LeapScreenTapGesture *)gesture;
                NSLog(@"Screen Tap id: %d, position: %@, direction: %@",
                    screenTapGesture.id,screenTapGesture.position, screenTapGesture.direction);
                if(drawLineFlag==false){
                    NSLog(@"Get the start position");
                    positionStart=SCNVector3Make(screenTapGesture.position.x,screenTapGesture.position.y,0.0);
                    drawLineFlag=true;
                }
                else{
                    NSLog(@"Get the end Position and change");
                    positionEnd=SCNVector3Make(screenTapGesture.position.x, screenTapGesture.position.y, 0.0);
                    [self changeSettings];
                    drawLineFlag=false;
                }
                
                //screenTapGesture.position.x
                //[//self chageSettings:lineNode];
                break;
            }
            default:
                NSLog(@"Unknown gesture type");
                break;
        }
    }
    //HACK::END LeapGesture
    //NSLog(@"The position (%f,%f)",firstHandNode.position.x,firstHandNode.position.y);
    
    
    if (indexOfCurrentHand < 1)
    {
        firstHandNode.opacity = 0.0;
        secondHandNode.opacity = 0.0;
    }
    else if (indexOfCurrentHand < 2)
    {
        secondHandNode.opacity = 0.0;
    }
    glBegin(GL_TRIANGLES);
    glColor3f(1.0, 0.0, 0.0);
    glVertex3f(0.0, 0.0, -100.0);
    glVertex3f(-200.0, 0.0, -100.0);
    glVertex3f(-200.0, 200.0, -100.0);
    glEnd();
    glutSolidSphere(100.0, 20, 20);
    //NSLog(@"haven't yet entered loop, Count %lu", (unsigned long)trackPoints.count);
   
    //for (LeapVector *it in trackPoints )
    //{
        //[page.view addSubview:item];
        
        //NSLog(@"Position of points,(%f,%f,%f)",it.x, it.y, it.z);
        
    //}
    //NSLog(@"completed for loop");
    //NSLog(@"",trackPoints);
}

//- (void)chageSettingsLineNodeHori{
- (void)chageSettingsHori:(SCNNode *)node{
    SCNVector3 positions[] = {
        SCNVector3Make(0.0, 0.0, 0.0),
        SCNVector3Make(10.0, 0.0, 0.0)
    };
    int indices[] = {0, 1};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    //[lineNode setGeometry:line];
    [node setGeometry:line];

}

//- (void)chageSettingsLineNodeVerti{
- (void)chageSettingsVerti:(SCNNode *)node{

    SCNVector3 positions[] = {
        SCNVector3Make(0.0, 0.0, 0.0),
        SCNVector3Make(0.0, 10.0, 0.0)
    };
    int indices[] = {0, 1};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    //[lineNode setGeometry:line];
    [node setGeometry:line];

}

//- (void)chageSettingsLineNodePlusSlope{
- (void)chageSettingsPlusSlope:(SCNNode *)node{

    SCNVector3 positions[] = {
        SCNVector3Make(0.0, 0.0, 0.0),
        SCNVector3Make(10.0, 10.0, 0.0)
    };
    int indices[] = {0, 1};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    [node setGeometry:line];
    //[lineNode setGeometry:line];
}

//- (void)chageSettingsLineNodeMinusSlope{
- (void)chageSettingsMinusSlope:(SCNNode *)node{
    SCNVector3 positions[] = {
        SCNVector3Make(0.0, 0.0, 0.0),
        SCNVector3Make(10.0, -10.0, 0.0)
    };
    int indices[] = {0, 1};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    [node setGeometry:line];
    //[lineNode setGeometry:line];
}

//- (void)chageSettingsLineNode{
- (void)chageSettings:(SCNNode *)node{
    SCNVector3 positions[] = {
        SCNVector3Make(0.0, 0.0, 0.0),
        SCNVector3Make(10.0, 0.0, 0.0)
    };
    int indices[] = {0, 1};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    [node setGeometry:line];
    //[node setPosition:SCNVector3Make(10.0, 0.0, 0.0)];
}

-(void)changeSettings{
    SCNVector3 positions[] = {
        positionStart,
        positionEnd,
        
    };
    //NSLog(@"ChangeSettings%@",positions);
    int indices[] = {0, 1};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    [lineNode setGeometry:line];
}


- (void)takeScreenShot
{
    NSLog(@"taking screen shot");
    NSBeep();
    if ( ! sessionQueue ) {
        sessionQueue = dispatch_queue_create("picture taking queue", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async( sessionQueue, ^{
        if ( ! session ) {
            session = [AVCaptureSession new];
            AVCaptureScreenInput *screenInput = [AVCaptureScreenInput new];
            screenInput.capturesCursor = NO;
            CGDirectDisplayID displayID = CGMainDisplayID();
            CGRect cropRect = CGDisplayBounds(displayID);
            cropRect.size.width /= 2;
            screenInput.scaleFactor = 1;
            
            screenInput.cropRect = cropRect;
            [session addInput:screenInput];
            AVCaptureStillImageOutput *stillImageOutput = [AVCaptureStillImageOutput new];
            [session addOutput:stillImageOutput];
        }
        
        [session startRunning];
        
        AVCaptureStillImageOutput *stillImageOutput = session.outputs[0];
        AVCaptureConnection *connection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
        {
            NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            //void *pointerToJPEGData = [data bytes];
            size_t jpegSize = data.length;
            NSLog(@"Captured the screen! jpegsize = %d", (int)jpegSize);
            static int number = 1;
            [data writeToFile:[NSString stringWithFormat:@"/tmp/screencapture_%d.jpg", number] atomically:YES];
            NSString* path=[NSString stringWithFormat:@"/tmp/screencapture_%d.jpg",number];
            makeNote( [path  UTF8String]);
            number++;
        //[data writeToURL:<#(NSURL *)#> options:<#(NSDataWritingOptions)#> error:<#(NSError *__autoreleasing *)#>]
            //[session stopRunning];
        }];
    });
    
}

@end
