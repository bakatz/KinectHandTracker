/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 *
 * Modified by Ben Katz (bakatz@vt.edu) 2011 for Mittelman Lab
 */

/* Lesson07View.m */

#import "Lesson07View.h"
#include <time.h>

@interface Lesson07View (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (void) checkLighting;
@end

@implementation Lesson07View

// Ambient light values
static GLfloat lightAmbient[] = { 0.5f, 0.5f, 0.5f, 1.0f };
// Diffuse light values
static GLfloat lightDiffuse[] = { 1.0f, 1.0f, 1.0f, 1.0f };
// Light position
static GLfloat lightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };
- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
   NSOpenGLPixelFormat *pixelFormat;

   colorBits = numColorBits;
   depthBits = numDepthBits;
   runningFullScreen = runFullScreen;
   originalDisplayMode = (NSDictionary *) CGDisplayCurrentMode(
                                             kCGDirectMainDisplay );
   xrot = yrot = xspeed = yspeed = filter = currentCube = 0;
    for(int i = 0; i < 3; i++) {
        xrots[i] = xrot;
        yrots[i] = yrot;
        xspeeds[i] = xspeed;
        yspeeds[i] = yspeed;
        zpositions[i] = -5.0f;
    }
   pixelFormat = [ self createPixelFormat:frame ];
   if( pixelFormat != nil )
   {
      self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
      [ pixelFormat release ];
      if( self )
      {
         [ [ self openGLContext ] makeCurrentContext ];
         if( runningFullScreen )
            [ [ self openGLContext ] setFullScreen ];
         [ self reshape ];
         if( ![ self initGL ] )
         {
            [ self clearGLContext ];
            self = nil;
         }
      }
   }
   else
      self = nil;

   return self;
}


/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
   NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
   int pixNum = 0;
   NSDictionary *fullScreenMode;
   NSOpenGLPixelFormat *pixelFormat;

   pixelAttribs[ pixNum++ ] = NSOpenGLPFADoubleBuffer;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAAccelerated;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFAColorSize;
   pixelAttribs[ pixNum++ ] = colorBits;
   pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
   pixelAttribs[ pixNum++ ] = depthBits;

   if( runningFullScreen )  // Do this before getting the pixel format
   {
      pixelAttribs[ pixNum++ ] = NSOpenGLPFAFullScreen;
      fullScreenMode = (NSDictionary *) CGDisplayBestModeForParameters(
                                           kCGDirectMainDisplay,
                                           colorBits, frame.size.width,
                                           frame.size.height, NULL );
      CGDisplayCapture( kCGDirectMainDisplay );
      CGDisplayHideCursor( kCGDirectMainDisplay );
      CGDisplaySwitchToMode( kCGDirectMainDisplay,
                             (CFDictionaryRef) fullScreenMode );
   }
   pixelAttribs[ pixNum ] = 0;
   pixelFormat = [ [ NSOpenGLPixelFormat alloc ]
                   initWithAttributes:pixelAttribs ];

   return pixelFormat;
}

- (void) selectLeftCube {
    currentCube = currentCube < 0 ? 1 : currentCube - 1;
}

- (void) selectRightCube {
    currentCube = currentCube > 0 ? -1 : currentCube + 1;
}

/*
 * Enable/disable full screen mode
 */
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame
{
   BOOL success = FALSE;
   NSOpenGLPixelFormat *pixelFormat;
   NSOpenGLContext *newContext;

   [ [ self openGLContext ] clearDrawable ];
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   runningFullScreen = enableFS;
   pixelFormat = [ self createPixelFormat:frame ];
   if( pixelFormat != nil )
   {
      newContext = [ [ NSOpenGLContext alloc ] initWithFormat:pixelFormat
                     shareContext:nil ];
      if( newContext != nil )
      {
         [ super setFrame:frame ];
         [ super setOpenGLContext:newContext ];
         [ newContext makeCurrentContext ];
         if( runningFullScreen )
            [ newContext setFullScreen ];
         [ self reshape ];
         if( [ self initGL ] )
            success = TRUE;
      }
      [ pixelFormat release ];
   }
   if( !success && runningFullScreen )
      [ self switchToOriginalDisplayMode ];

   return success;
}


/*
 * Switch to the display mode in which we originally began
 */
- (void) switchToOriginalDisplayMode
{
   CGDisplaySwitchToMode( kCGDirectMainDisplay,
                          (CFDictionaryRef) originalDisplayMode );
   CGDisplayShowCursor( kCGDirectMainDisplay );
   CGDisplayRelease( kCGDirectMainDisplay );
}


/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{
   if( ![ self loadGLTextures ])
      return FALSE;

   glEnable( GL_TEXTURE_2D );                // Enable texture mapping
   glShadeModel( GL_SMOOTH );                // Enable smooth shading
   glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
   // Really nice perspective calculations
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   // Setup ambient light
   glLightfv( GL_LIGHT1, GL_AMBIENT, lightAmbient );
   // Setup diffuse light
   glLightfv( GL_LIGHT1, GL_DIFFUSE, lightDiffuse );
   // Position the light
   glLightfv( GL_LIGHT1, GL_POSITION, lightPosition );
   glEnable( GL_LIGHT1 );   // Enable light 1

   [ self checkLighting ];

   return TRUE;
}


/*
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
   BOOL status = FALSE;

   if( [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                                    [ [ NSBundle mainBundle ] resourcePath ],
                                    "Crate.bmp" ] intoIndex:0 ] )
   {
      status = TRUE;

      glGenTextures( 3, &texture[ 0 ] );   // Create the textures

      // Create nearest filtered texture
      glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
      glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );
      // Create linear filtered texture
      glBindTexture( GL_TEXTURE_2D, texture[ 1 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
      glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ 0 ].width,
                    texSize[ 0 ].height, 0, texFormat[ 0 ],
                    GL_UNSIGNED_BYTE, texBytes[ 0 ] );
      // Create mipmapped texture
      glBindTexture( GL_TEXTURE_2D, texture[ 2 ] );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                       GL_LINEAR_MIPMAP_NEAREST );
      gluBuild2DMipmaps( GL_TEXTURE_2D, 3, texSize[ 0 ].width,
                         texSize[ 0 ].height, texFormat[ 0 ],
                         GL_UNSIGNED_BYTE, texBytes[ 0 ] );

      free( texBytes[ 0 ] );
   }

   return status;
}


/*
 * The NSBitmapImageRep is going to load the bitmap, but it will be
 * setup for the opposite coordinate system than what OpenGL uses, so
 * we copy things around.
 */
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex
{
   BOOL success = FALSE;
   NSBitmapImageRep *theImage;
   int bitsPPixel, bytesPRow;
   unsigned char *theImageData;
   int rowNum, destRowNum;

   theImage = [ NSBitmapImageRep imageRepWithContentsOfFile:filename ];
   if( theImage != nil )
   {
      bitsPPixel = [ theImage bitsPerPixel ];
      bytesPRow = [ theImage bytesPerRow ];
      if( bitsPPixel == 24 )        // No alpha channel
         texFormat[ texIndex ] = GL_RGB;
      else if( bitsPPixel == 32 )   // There is an alpha channel
         texFormat[ texIndex ] = GL_RGBA;
      texSize[ texIndex ].width = [ theImage pixelsWide ];
      texSize[ texIndex ].height = [ theImage pixelsHigh ];
      texBytes[ texIndex ] = calloc( bytesPRow * texSize[ texIndex ].height,
                                     1 );
      if( texBytes[ texIndex ] != NULL )
      {
         success = TRUE;
         theImageData = [ theImage bitmapData ];
         destRowNum = 0;
         for( rowNum = texSize[ texIndex ].height - 1; rowNum >= 0;
              rowNum--, destRowNum++ )
         {
            // Copy the entire row in one shot
            memcpy( texBytes[ texIndex ] + ( destRowNum * bytesPRow ),
                    theImageData + ( rowNum * bytesPRow ),
                    bytesPRow );
         }
      }
   }

   return success;
}
/*
 * Resize ourself
 */
- (void) reshape
{ 
   NSRect sceneBounds;
   
   [ [ self openGLContext ] update ];
   sceneBounds = [ self bounds ];
   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height,
                   0.1f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
    

    //glPushMatrix();
    
   // Clear the screen and depth buffer
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   

    for (int x = -1; x < 2; x++)
    {
        glLoadIdentity();   // Reset the current modelview matrix
        glTranslatef( (float) 3 * x, 0.0f, zpositions[x+1] );   // In/out of screen by zPos
        if(currentCube == x) {
            // Rotate on X axis
            glRotatef( xrots[x+1], 1.0f, 0.0f, 0.0f );
            // Rotate on Y axis
            glRotatef( yrots[x+1], 0.0f, 1.0f, 0.0f );
            glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
        } else {
            glRotatef( xrots[x+1], 1.0f, 0.0f, 0.0f );
            // Rotate on Y axis
            glRotatef( yrots[x+1], 0.0f, 1.0f, 0.0f );
            glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
        }
        
        // Set color.
        //TODO
       
        
        
        // Select our texture
        glBindTexture( GL_TEXTURE_2D, texture[ filter ] );

    
        glBegin( GL_QUADS ); 
        // Front Face
        glNormal3f( 0.0f, 0.0f, 1.0f );      // Normal Pointing Towards Viewer
        glTexCoord2f( 0.0f, 0.0f );
        glVertex3f( -1.0f, -1.0f,  1.0f );   // Point 1 (Front) 
        glTexCoord2f( 1.0f, 0.0f );
        glVertex3f(  1.0f, -1.0f,  1.0f );   // Point 2 (Front)
        glTexCoord2f( 1.0f, 1.0f );
        glVertex3f(  1.0f,  1.0f,  1.0f );   // Point 3 (Front)
        glTexCoord2f( 0.0f, 1.0f );
        glVertex3f( -1.0f,  1.0f,  1.0f );   // Point 4 (Front)
        // Back Face
        glNormal3f( 0.0f, 0.0f, -1.0f );     // Normal Pointing Away From Viewer
        glTexCoord2f( 1.0f, 0.0f );
        glVertex3f( -1.0f, -1.0f, -1.0f );   // Point 1 (Back)
        glTexCoord2f( 1.0f, 1.0f );
        glVertex3f( -1.0f,  1.0f, -1.0f );   // Point 2 (Back)
        glTexCoord2f( 0.0f, 1.0f );
        glVertex3f(  1.0f,  1.0f, -1.0f );   // Point 3 (Back)
        glTexCoord2f( 0.0f, 0.0f );
        glVertex3f(  1.0f, -1.0f, -1.0f );   // Point 4 (Back)
        // Top Face
        glNormal3f( 0.0f, 1.0f, 0.0f );      // Normal Pointing Up
        glTexCoord2f( 0.0f, 1.0f );
        glVertex3f( -1.0f,  1.0f, -1.0f );   // Point 1 (Top)
        glTexCoord2f( 0.0f, 0.0f );
        glVertex3f( -1.0f,  1.0f,  1.0f );   // Point 2 (Top)
        glTexCoord2f( 1.0f, 0.0f );
        glVertex3f(  1.0f,  1.0f,  1.0f );   // Point 3 (Top)
        glTexCoord2f( 1.0f, 1.0f );
        glVertex3f(  1.0f,  1.0f, -1.0f );   // Point 4 (Top)
        // Bottom Face
        glNormal3f( 0.0f, -1.0f, 0.0f );     // Normal Pointing Down
        glTexCoord2f( 1.0f, 1.0f );
        glVertex3f( -1.0f, -1.0f, -1.0f );   // Point 1 (Bottom)
        glTexCoord2f( 0.0f, 1.0f );
        glVertex3f(  1.0f, -1.0f, -1.0f );   // Point 2 (Bottom)
        glTexCoord2f( 0.0f, 0.0f );
        glVertex3f(  1.0f, -1.0f,  1.0f );   // Point 3 (Bottom)
        glTexCoord2f( 1.0f, 0.0f );
        glVertex3f( -1.0f, -1.0f,  1.0f );   // Point 4 (Bottom)
        // Right face
        glNormal3f( 1.0f, 0.0f, 0.0f);       // Normal Pointing Right
        glTexCoord2f( 1.0f, 0.0f );
        glVertex3f(  1.0f, -1.0f, -1.0f );   // Point 1 (Right)
        glTexCoord2f( 1.0f, 1.0f );
        glVertex3f(  1.0f,  1.0f, -1.0f );   // Point 2 (Right)
        glTexCoord2f( 0.0f, 1.0f );
        glVertex3f(  1.0f,  1.0f,  1.0f );   // Point 3 (Right)
        glTexCoord2f( 0.0f, 0.0f );
        glVertex3f(  1.0f, -1.0f,  1.0f );   // Point 4 (Right)
        // Left Face
        glNormal3f( -1.0f, 0.0f, 0.0f );     // Normal Pointing Left
        glTexCoord2f( 0.0f, 0.0f );
        glVertex3f( -1.0f, -1.0f, -1.0f );   // Point 1 (Left)
        glTexCoord2f( 1.0f, 0.0f );
        glVertex3f( -1.0f, -1.0f,  1.0f );   // Point 2 (Left)
        glTexCoord2f( 1.0f, 1.0f );
        glVertex3f( -1.0f,  1.0f,  1.0f );   // Point 3 (Left)
        glTexCoord2f( 0.0f, 1.0f );
        glVertex3f( -1.0f,  1.0f, -1.0f );   // Point 4 (Left)
        glEnd();                             // Done Drawing Quads
    }
   
    if([self openGLContext] != nil) {}
    [ [ self openGLContext ] flushBuffer ];
    double rotFactor = 1.1;
    //if(xrot >= 0 && yrot >= 0) {
    xrots[currentCube+1] += xspeeds[currentCube+1];
    yrots[currentCube+1] += yspeeds[currentCube+1]; 
    //}
    //if(xrot > 0) {
    //[self decreaseXSpeed:xspeed*0.5];
    //}
    //if(yrot > 0) {
    //[self decreaseYSpeed:yspeed*0.5];
    //}
    
    xspeeds[currentCube+1] /= rotFactor;
    yspeeds[currentCube+1] /= rotFactor;
    //rotFactor /= 1.1;
    
    //printf("x rot: %f, y rot: %f\n", xrot, yrot);


}



/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
   return runningFullScreen;
}


- (void) toggleLight
{
   light = !light;
   [ self checkLighting ];
}


- (void) selectNextFilter
{
   filter = ( filter + 1 ) % 3;
}


- (void) decreaseZPos:(int)amt
{
   zpositions[currentCube+1] -= amt;
}


- (void) increaseZPos:(int)amt
{
   zpositions[currentCube+1] += amt;
}


- (void) decreaseXSpeed:(int)amt
{
   xspeeds[currentCube+1] -= amt;
}

- (void) increaseXSpeed:(int)amt
{
   xspeeds[currentCube+1] += amt;
}

- (void) decreaseYSpeed:(int)amt
{
   yspeeds[currentCube+1] -= amt;
}

- (void) increaseYSpeed:(int)amt
{
   yspeeds[currentCube+1] += amt;
}

- (void) addToXRot:(int)diff
{
    xrots[currentCube+1] += diff;
}

- (void) addToYRot:(int)diff
{
    yrots[currentCube+1] += diff;
}

- (void) setCurrentCube:(int)idx
{
    currentCube = idx;
}

- (void) checkLighting
{
   if( !light )
      glDisable( GL_LIGHTING );
   else
      glEnable( GL_LIGHTING );
}


/*
 * Cleanup
 */
- (void) dealloc
{
    [super dealloc];
   if( runningFullScreen )
      [ self switchToOriginalDisplayMode ];
   [ originalDisplayMode release ];
}

@end
