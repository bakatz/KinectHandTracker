/*
 *  openni_backend.cpp
 *  webkit-plugin-mac
 *
 *  Created by Roy Shilkrot on 9/30/11.
 *  Copyright 2011 MIT. All rights reserved.
 *
 */

#include "openni_backend.hpp"

// Headers for OpenNI
#include <XnOpenNI.h>
#include <XnCppWrapper.h>
#include <XnHash.h>
#include <XnLog.h>
#include <XnUSB.h>

#define VID_MICROSOFT 0x45e
#define PID_NUI_MOTOR 0x02b0

// Header for NITE
#include "XnVNite.h"

#include "HandMessageListener.h"

#include <iostream>

#define CHECK_RC(rc, what)											\
	if (rc != XN_STATUS_OK)											\
	{																\
		printf("%s failed: %s\n", what, xnGetStatusString(rc));		\
		return rc;													\
	}

#define CHECK_ERRORS(rc, errors, what)		\
	if (rc == XN_STATUS_NO_NODE_PRESENT)	\
	{										\
		XnChar strError[1024];				\
		errors.ToString(strError, 1024);	\
		printf("%s\n", strError);			\
		return (rc);						\
	}

#define GESTURE_TO_USE "Wave"

using namespace xn;
using namespace std;

typedef enum
{
	IN_SESSION,
	NOT_IN_SESSION,
	QUICK_REFOCUS
} SessionState;

typedef enum
{
    LED_OFF    = 0,
    LED_GREEN  = 1,
    LED_RED    = 2,
    LED_YELLOW = 3, //(actually orange)
    LED_BLINK_YELLOW = 4, //(actually orange)
    LED_BLINK_GREEN = 5,
    LED_BLINK_RED_YELLOW = 6 //(actually red/orange)
} KinectLEDColor;


// Callback for when the focus is in progress
void XN_CALLBACK_TYPE FocusProgress(const XnChar* strFocus, const XnPoint3D& ptPosition, XnFloat fProgress, void* UserCxt)
{
	printf("Focus progress: %s @(%f,%f,%f): %f\n", strFocus, ptPosition.X, ptPosition.Y, ptPosition.Z, fProgress);
}

void XN_CALLBACK_TYPE GestureIntermediateStageCompletedHandler(xn::GestureGenerator& generator, const XnChar* strGesture, const XnPoint3D* pPosition, void* pCookie)
{
	printf("Gesture %s: Intermediate stage complete (%f,%f,%f)\n", strGesture, pPosition->X, pPosition->Y, pPosition->Z);
}
void XN_CALLBACK_TYPE GestureReadyForNextIntermediateStageHandler(xn::GestureGenerator& generator, const XnChar* strGesture, const XnPoint3D* pPosition, void* pCookie)
{
	printf("Gesture %s: Ready for next intermediate stage (%f,%f,%f)\n", strGesture, pPosition->X, pPosition->Y, pPosition->Z);
}
void XN_CALLBACK_TYPE GestureProgressHandler(xn::GestureGenerator& generator, const XnChar* strGesture, const XnPoint3D* pPosition, XnFloat fProgress, void* pCookie)
{
	printf("Gesture %s progress: %f (%f,%f,%f)\n", strGesture, fProgress, pPosition->X, pPosition->Y, pPosition->Z);
}

void XN_CALLBACK_TYPE SessionStarting(const XnPoint3D& ptPosition, void* UserCxt);
void XN_CALLBACK_TYPE SessionEnding(void* UserCxt);
void XN_CALLBACK_TYPE NoHands(void* UserCxt);

// xml to initialize OpenNI
#define SAMPLE_XML_PATH "../Resources/Sample-Tracking.xml"


class OpenNIBackend {
public:
	OpenNIBackend():g_SessionState(NOT_IN_SESSION),running(true),terminated(false) {}
	
	void run() {
		printf("start openni backend thread\n");
		terminated = false;
		while (running) {
			XnMapOutputMode mode;
			g_DepthGenerator.GetMapOutputMode(mode);
			// Read next available data
			g_Context.WaitOneUpdateAll(g_DepthGenerator);
			// Update NITE tree
			g_pSessionManager->Update(&g_Context);
		}
		terminated = true;
		printf("end openni backend thread\n");
	}
	void stop() { printf("stopping openni backend...\n"); running = false;}
	bool isDead() { return terminated; }
    
    int setKinectLEDColor(KinectLEDColor color) {
        
        XN_USB_DEV_HANDLE dev;
		
		int angle = 20;
		
		XnStatus rc = XN_STATUS_OK;
		
		rc = xnUSBInit();
		CHECK_RC(rc,"init usb device");
		
		rc = xnUSBOpenDevice(VID_MICROSOFT, PID_NUI_MOTOR, NULL, NULL, &dev);
		CHECK_RC(rc,"open usb device");
		
		uint8_t empty[0x1];
		angle = angle * 2;
        
        rc = xnUSBSendControl(dev, XN_USB_CONTROL_TYPE_VENDOR, 0x06, color, 0x0, empty, 0x0, 0);

        
        
		CHECK_RC(rc,"send usb command");
		
		rc = xnUSBCloseDevice(dev);
        rc = xnUSBShutdown();
		CHECK_RC(rc,"close usb device");
		
		return rc;
    }
	
	int setKinectAngle() {
		XN_USB_DEV_HANDLE dev;
		
		int angle = 20;
		
		XnStatus rc = XN_STATUS_OK;
		
		rc = xnUSBOpenDevice(VID_MICROSOFT, PID_NUI_MOTOR, NULL, NULL, &dev);
		CHECK_RC(rc,"open usb device");
		
		uint8_t empty[0x1];
		angle = angle * 2;
        
		rc = xnUSBSendControl(dev,
							  XN_USB_CONTROL_TYPE_VENDOR,
							  0x31,
							  (XnUInt16)angle,
							  0x0,
							  empty,
							  0x0, 0);
        
        
        
        
//        request  request  value        index   data   length
//        0x40     0x06     led_option   0x0     empty  0
        
        
		CHECK_RC(rc,"send usb command");
		
		rc = xnUSBCloseDevice(dev);
        rc = xnUSBShutdown();
		CHECK_RC(rc,"close usb device");
		
		return rc;
	}
	
	int init() {
		running = true;
		terminated = false;
        XnStatus rc = XN_STATUS_OK;
        rc = xnUSBInit();
		CHECK_RC(rc,"init usb device");
		setKinectAngle();
        setKinectLEDColor(LED_BLINK_GREEN);
		
		
		xn::EnumerationErrors errors;
		
		// Initialize OpenNI
		rc = g_Context.InitFromXmlFile(SAMPLE_XML_PATH, g_ScriptNode, &errors);
		CHECK_ERRORS(rc, errors, "InitFromXmlFile");
		CHECK_RC(rc, "InitFromXmlFile");
        
        if(rc != XN_STATUS_OK) {
            printf("Caught fatal error, exiting with failure.\n");
            exit(-1);
        }
		
		rc = g_Context.FindExistingNode(XN_NODE_TYPE_DEPTH, g_DepthGenerator);
		CHECK_RC(rc, "Find depth generator");
		rc = g_Context.FindExistingNode(XN_NODE_TYPE_HANDS, g_HandsGenerator);
		CHECK_RC(rc, "Find hands generator");
		rc = g_Context.FindExistingNode(XN_NODE_TYPE_GESTURE, g_GestureGenerator);
		CHECK_RC(rc, "Find gesture generator");
		
		//	XnCallbackHandle h;
		//	if (g_HandsGenerator.IsCapabilitySupported(XN_CAPABILITY_HAND_TOUCHING_FOV_EDGE))
		//	{
		//		g_HandsGenerator.GetHandTouchingFOVEdgeCap().RegisterToHandTouchingFOVEdge(TouchingCallback, NULL, h);
		//	}
		
		XnCallbackHandle hGestureIntermediateStageCompleted, hGestureProgress, hGestureReadyForNextIntermediateStage;
		g_GestureGenerator.RegisterToGestureIntermediateStageCompleted(GestureIntermediateStageCompletedHandler, NULL, hGestureIntermediateStageCompleted);
		g_GestureGenerator.RegisterToGestureReadyForNextIntermediateStage(GestureReadyForNextIntermediateStageHandler, NULL, hGestureReadyForNextIntermediateStage);
		g_GestureGenerator.RegisterGestureCallbacks(NULL, GestureProgressHandler, NULL, hGestureProgress);
		
		g_HandsGenerator.SetSmoothing(0.1);
		
		// Create NITE objects
		g_pSessionManager = new XnVSessionManager;
		rc = g_pSessionManager->Initialize(&g_Context, "Click,Wave", "RaiseHand"); //args: context, init gestures, quick refocus gestures
		CHECK_RC(rc, "SessionManager::Initialize");
		
		g_pSessionManager->RegisterSession(this, SessionStarting, SessionEnding, FocusProgress);
		
		g_pHandListener = new HandPointControl(g_DepthGenerator,g_pSessionManager);
		g_pFlowRouter = new XnVFlowRouter;
		g_pFlowRouter->SetActive(g_pHandListener);
		
		g_pSessionManager->AddListener(g_pFlowRouter);
		
		g_pHandListener->RegisterNoPoints(this, NoHands);
				
		// Initialization done. Start generating
		rc = g_Context.StartGeneratingAll();
		CHECK_RC(rc, "StartGenerating");
		
		return rc == XN_STATUS_OK;
	}
	
	SessionState g_SessionState;
private:
	bool running,terminated;
	
	// OpenNI objects
	xn::Context g_Context;
	xn::ScriptNode g_ScriptNode;
	xn::DepthGenerator g_DepthGenerator;
	xn::HandsGenerator g_HandsGenerator;
	xn::GestureGenerator g_GestureGenerator;
	
	// NITE objects
	XnVSessionManager* g_pSessionManager;
	XnVFlowRouter* g_pFlowRouter;
	
	HandPointControl* g_pHandListener;
};

// callback for session start
void XN_CALLBACK_TYPE SessionStarting(const XnPoint3D& ptPosition, void* UserCxt)
{
	printf("Session start: (%f,%f,%f)\n", ptPosition.X, ptPosition.Y, ptPosition.Z);
	((OpenNIBackend*)UserCxt)->g_SessionState = IN_SESSION;
}
// Callback for session end
void XN_CALLBACK_TYPE SessionEnding(void* UserCxt)
{
	printf("Session end\n");
	((OpenNIBackend*)UserCxt)->g_SessionState = NOT_IN_SESSION;
}
void XN_CALLBACK_TYPE NoHands(void* UserCxt)
{
	if (((OpenNIBackend*)UserCxt)->g_SessionState != NOT_IN_SESSION)
	{
		printf("Hand went off screen. Trying quick refocus -- checking for raised hand...\n");
		((OpenNIBackend*)UserCxt)->g_SessionState = QUICK_REFOCUS;
	}
}


OpenNIBackend onib;

int openni_backend(void* _arg) { onib.run(); return 0; }
void kill_openni_backend() { onib.stop(); }
bool is_openni_backend_dead() { return onib.isDead(); }
int init_openni_backend() { return onib.init(); }
