/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson07Controller.m */

#import "Lesson07Controller.h"
#import <Foundation/Foundation.h>
#include "openni_backend.hpp"

@interface Lesson07Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
- (void) moveCube:(int)x:(int)y:(int)z;
- (void) moveCubeDown:(double)amount;
- (void) moveCubeLeft:(double)amount;
- (void) moveCubeRight:(double)amount;
- (void) moveCubeUp:(double)amount;
- (void) pushCubeIn:(double)amount;
- (void) pullCubeOut:(double)amount;
- (void) selectLeftCube;
- (void) selectRightCube;
- (BOOL) isTwoHands;
- (void) setTwoHands:(BOOL)two;

@end

@implementation Lesson07Controller
void* selfPtr = NULL;
const bool USE_SWIPE_MOTION=FALSE;
int oldX = 0;
int oldY = 0;
int oldZ = 0;
bool firstZ = TRUE;

+ (void) gestureEngineThread 
{
    printf("Initializing OpenNI gesture engine...\n");
    init_openni_backend();
    printf("Done intializing gesture engine. Running engine...\n");
    openni_backend(0);
    //init_gesture_engine();
    //gesture_engine(0);
}
- (void) awakeFromNib
{  
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   glView = [ [ Lesson07View alloc ] initWithFrame:[ glWindow frame ]
              colorBits:16 depthBits:16 fullscreen:FALSE ];
   if( glView != nil )
   {
      [ glWindow setContentView:glView ];
      [ glWindow makeKeyAndOrderFront:self ];
       selfPtr = self;
      [ self setupRenderTimer ];
       //start gesture engine as a thread so we can send events back and forth concurrently
      [ NSThread detachNewThreadSelector:@selector(gestureEngineThread) toTarget:[Lesson07Controller class] withObject:nil ];
   }
   else
      [ self createFailed ];
}  


void receiveMsg(char* command, const char* data) { // (char* command) {
    //takeMoveAction(selfPtr, command, data);
    
    if(strcmp(command, "register") == 0) {
        double amount = atof(data);
        if(amount <= 1) { //TODO: hide window if there aren't any hands on screen.
            printf("Kinect requested set one-hand mode.\n");
            [(id) selfPtr setTwoHands:FALSE];
        } else {
            printf("Kinect requested set two-hand mode.\n");
            [(id) selfPtr setTwoHands:TRUE];
        }
    }
    
    if(![(id) selfPtr isTwoHands]) { //one hand gestures
        
        if(USE_SWIPE_MOTION) {
            double amount = atof(data);
            if(strcmp(command, "rotate_up") == 0) {
                printf("Kinect requested rotate cube up, velocity: %f\n", amount);
                [(id) selfPtr moveCubeUp:amount];
            } else if(strcmp(command, "rotate_down") == 0) {
                printf("Kinect requested rotate cube down, velocity: %f\n", amount);
                [(id) selfPtr moveCubeDown:amount];
            } else if(strcmp(command, "rotate_left") == 0) {
                printf("Kinect requested rotate cube left, velocity: %f\n", amount);
                [(id) selfPtr moveCubeLeft:amount];
            } else if(strcmp(command, "rotate_right") == 0) {
                printf("Kinect requested rotate cube right, velocity: %f\n", amount);
                [(id) selfPtr moveCubeRight:amount];
            } else if(strcmp(command, "push") == 0) {
                printf("Kinect requested push cube, velocity: %f\n", amount); //TODO: make use of this with another gesture?
                [(id) selfPtr pushCubeIn:amount];
            } else if(strcmp(command,"pull") == 0) {
                printf("Kinect requested pull cube, velocity: %f\n", amount); //TODO: make use of this with another gesture?
                amount = abs(amount);
                [(id) selfPtr pullCubeOut:amount];
            }else if(strcmp(command,"circle") == 0){
                printf("Kinect requested change in mode, velocity: %f\n", amount);  //changes mode from push/pull to rotation.
            }
        } else {
            if(strcmp(command, "move") == 0) {
                char* tmp = (char*)malloc((sizeof(char)*strlen(data))+1);
                strcpy(tmp, data);
                char* xStr = strtok(tmp, ",");
                char* yStr = strtok(NULL, ",");
                char* zStr = strtok(NULL, ",");
                int x = atoi(xStr);
                int y = atoi(yStr);
                int z = atoi(zStr);
                free(tmp);
                //printf("Kinect requested move cube to coordinates: [%d, %d, %d]\n", x, y, z);
                [(id) selfPtr moveCube:x:y:z];
            }
        }
        
        
        
    } else {
        if(strcmp(command, "rotate_up") == 0) { //two hand gestures
            printf("Kinect requested select current cube\n"); //this will force one hand mode on the selected cube.
        } else if(strcmp(command, "rotate_left") == 0) {
            oldX = 0;
            oldY = 0;
            oldZ = 0;
            printf("Kinect requested move cube pointer left\n");
            [(id) selfPtr selectLeftCube];
        } else if(strcmp(command, "rotate_right") == 0) {
            oldX = 0;
            oldY = 0;
            oldZ = 0;
            printf("Kinect requested move cube pointer right\n");
            [(id) selfPtr selectRightCube];
        }
    }

    /*
     case NSPageUpFunctionKey:
     [ glView decreaseZPos:15 ];
     break;
     
     case NSPageDownFunctionKey:
     [ glView increaseZPos:15 ];
     break;
     
     case NSUpArrowFunctionKey:
     [ glView decreaseXSpeed:15 ];
     break;
     
     case NSDownArrowFunctionKey:
     [ glView increaseXSpeed:15 ];
     break;
     
     case NSRightArrowFunctionKey:
     [ glView increaseYSpeed:15 ];
     break;
     
     case NSLeftArrowFunctionKey:
     [ glView decreaseYSpeed:15 ];
     break;*/
    //printf("Got msg from kinect: %s\n", command);
    
}
- (void) moveCubeUp:(double)amount
{
    amount /= 3.5;
    printf("Moving actual amount: %f\n", amount);
    [ glView decreaseXSpeed:amount ];
}

- (void) moveCubeDown:(double)amount
{
    amount /= 3.5;
    printf("Moving actual amount: %f\n", amount);
    [ glView increaseXSpeed:amount ];
}

- (void) moveCubeLeft:(double)amount
{
    amount /= 4.0;
    printf("Moving actual amount: %f\n", amount);
    [ glView decreaseYSpeed:amount ];
}

- (void) moveCubeRight:(double)amount
{
    amount /= 4.0;
    printf("Moving actual amount: %f\n", amount);
    [ glView increaseYSpeed:amount ];
}
-(void) pushCubeIn:(double)amount
{
    amount /= 20.0;
    [ glView decreaseZPos:amount ];
}
- (void) pullCubeOut:(double)amount
{
    amount /= 20.0;
    [ glView increaseZPos:amount ];
}

- (void) moveCube:(int)x:(int)y:(int)z
{
    int xDiff = x - oldX;
    int yDiff = y - oldY;
    int zDiff = z - oldZ;
    oldX = x;
    oldY = y;
    oldZ = z;
    [ glView addToXRot:xDiff];
    [ glView addToYRot:yDiff];
    if(firstZ) {
        firstZ = FALSE;
    } else {
       // if(abs(zDiff) >= 5.0) {
            [ glView increaseZPos:zDiff/15];
       // }
    }
}

-(void) selectLeftCube {
    [ glView selectLeftCube ];
}

-(void) selectRightCube {
    [ glView selectRightCube ];
}

- (BOOL) isTwoHands
{
    return twoHands;
}
             
- (void) setTwoHands:(BOOL)two 
{
    twoHands = two;                 
}
/*
 * Setup timer to update the OpenGL view.
 */
- (void) setupRenderTimer
{
   NSTimeInterval timeInterval = 0.005;

   renderTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval
                             target:self
                             selector:@selector( updateGLView: )
                             userInfo:nil repeats:YES ] retain ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSEventTrackingRunLoopMode ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSModalPanelRunLoopMode ];
}


/*
 * Called by the rendering timer.
 */
- (void) updateGLView:(NSTimer *)timer
{
   if( glView != nil )
      [ glView drawRect:[ glView frame ] ];
}  


/*
 * Handle key presses
 */
- (void) keyDown:(NSEvent *)theEvent
{
   unichar unicodeKey;

   unicodeKey = [ [ theEvent characters ] characterAtIndex:0 ];
   switch( unicodeKey )
   {
           //printf("Key pressed: %c", unicodeKey);
      case 'l':
      case 'L':
         if( ![ theEvent isARepeat ] )
            [ glView toggleLight ];
         break;

      case 'f':
      case 'F':
         if( ![ theEvent isARepeat ] )
            [ glView selectNextFilter ];
         break;

      case NSPageUpFunctionKey:
           [ glView decreaseZPos:15 ];
         break;

      case NSPageDownFunctionKey:
           [ glView increaseZPos:15 ];
         break;

      case NSUpArrowFunctionKey:
           [ glView decreaseXSpeed:15 ];
         break;

      case NSDownArrowFunctionKey:
           [ glView increaseXSpeed:15 ];
         break;

      case NSRightArrowFunctionKey:
           [ glView increaseYSpeed:15 ];
         break;

      case NSLeftArrowFunctionKey:
           [ glView decreaseYSpeed:15 ];
         break;
       case 27:
           kill_openni_backend();
           //kill_gesture_engine();
           exit(0);
           break;
   }
}


/*
 * Set full screen.
 */
- (IBAction)setFullScreen:(id)sender
{
   [ glWindow setContentView:nil ];
   if( [ glView isFullScreen ] )
   {
      if( ![ glView setFullScreen:FALSE inFrame:[ glWindow frame ] ] )
         [ self createFailed ];
      else
         [ glWindow setContentView:glView ];
   }
   else
   {
      if( ![ glView setFullScreen:TRUE
                    inFrame:NSMakeRect( 0, 0, 800, 600 ) ] )
         [ self createFailed ];
   }
}


/*
 * Called if we fail to create a valid OpenGL view
 */
- (void) createFailed
{
   NSWindow *infoWindow;

   infoWindow = NSGetCriticalAlertPanel( @"Initialization failed",
                                         @"Failed to initialize OpenGL",
                                         @"OK", nil, nil );
   [ NSApp runModalForWindow:infoWindow ];
   [ infoWindow close ];
   [ NSApp terminate:self ];
}


/* 
 * Cleanup
 */
- (void) dealloc
{
    [ super dealloc ];
   [ glWindow release ]; 
   [ glView release ];
   if( renderTimer != nil && [ renderTimer isValid ] )
      [ renderTimer invalidate ];
}

@end
