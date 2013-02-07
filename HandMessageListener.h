/*
 *  HandMessageListener.h
 *  OpenniTry
 *
 *  Created by Roy Shilkrot on 9/30/11.
 *  Copyright 2011 MIT. All rights reserved.
 *  
 *  Modified by Ben Katz on 12/7/11
 */

#ifndef _HANDMESSAGELISTENER_H
#define _HANDMESSAGELISTENER_H

#include <XnCppWrapper.h>
#include <XnVPointControl.h>
#include <XnVFlowRouter.h>
#include <XnVSwipeDetector.h>
#include <XnVSelectableSlider1D.h>
#include <XnVSteadyDetector.h>
#include <XnVBroadcaster.h>
#include <XnVPushDetector.h>
#include <XnVWaveDetector.h>
#include <XnVSessionManager.h>
#include <XnVCircleDetector.h>

#include <sstream>
using namespace std;

extern void send_event(char* etype, const char* edata);
//void send_event(char* etype, char* edata) {
//    printf("test\n");
//}
class HandPointControl : public XnVPointControl {

public:
	HandPointControl(xn::DepthGenerator depthGenerator, XnVSessionManager* sessionManager):m_DepthGenerator(depthGenerator),m_SessionManager(sessionManager) {
//		m_pInnerFlowRouter = new XnVFlowRouter;
		m_pPushDetector = new XnVPushDetector;
		m_pSwipeDetector = new XnVSwipeDetector();//false);
        m_pSwipeDetector->SetSteadyDuration(50); //50 ms steady duration, to avoid random hand movements throwing off the gesture calculation
        //m_pSwipeDetector->SetMotionTime(500);
        m_pSwipeDetector->SetMotionSpeedThreshold(0.35f); //swipes should be faster then regular movement
		m_pCircleDetector = new XnVCircleDetector;
		m_pCircleDetector->SetMinRadius(150); //circles should be big enough to prevent confusion with random movement'
        m_pCircleDetector->SetMinimumPoints(50);
		
//		m_pInnerFlowRouter->SetActive(m_pPushDetector);
		
		// Add the push detector and flow manager to the broadcaster
//		m_Broadcaster.AddListener(m_pInnerFlowRouter);
//		m_Broadcaster.AddListener(m_pPushDetector);
		
		// Push
		m_pPushDetector->RegisterPush(this, &Push_Pushed);
		m_pCircleDetector->RegisterCircle(this, &ACircle);
		//m_pWaveDetector->RegisterWave(this, &Wave_Waved);
		m_pSwipeDetector->RegisterSwipeLeft(this, &Swipe_Left);
		m_pSwipeDetector->RegisterSwipeRight(this, &Swipe_Right);
		m_pSwipeDetector->RegisterSwipeUp(this, &Swipe_Up);
		m_pSwipeDetector->RegisterSwipeDown(this, &Swipe_Down);
        numHands = 0;
	}
	
	void Update(XnVMessage* pMessage)
	{
		XnVPointControl::Update(pMessage);
		//m_Broadcaster.Update(pMessage);
		m_pPushDetector->Update(pMessage);
		//m_pWaveDetector->Update(pMessage);
		m_pCircleDetector->Update(pMessage);
		m_pSwipeDetector->Update(pMessage);
	}
	static void XN_CALLBACK_TYPE Swipe_Left(XnFloat fVelocity, XnFloat fAngle, void* pUserCxt) {
        printf("swipe left, velocity: %f, angle: %f\n", fVelocity, fAngle);
        stringstream ss;
        ss << fVelocity * 100.0;
        send_event("rotate_left", ss.str().c_str());//fVelocity * 100.0);
		//send_event("SwipeLeft", "");
	}
	static void XN_CALLBACK_TYPE Swipe_Right(XnFloat fVelocity, XnFloat fAngle, void* pUserCxt) {
        printf("swipe right, velocity: %f, angle: %f\n", fVelocity, fAngle);
        stringstream ss;
        ss << fVelocity * 100.0;
        send_event("rotate_right", ss.str().c_str());//fVelocity * 100.0);
		//send_event("SwipeRight", "");
	}
	static void XN_CALLBACK_TYPE Swipe_Up(XnFloat fVelocity, XnFloat fAngle, void* pUserCxt) {
        printf("swipe up, velocity: %f, angle: %f\n", fVelocity, fAngle);
		stringstream ss;
        ss << fVelocity * 100.0;
        send_event("rotate_up", ss.str().c_str());//fVelocity * 100.0);
	}
	static void XN_CALLBACK_TYPE Swipe_Down(XnFloat fVelocity, XnFloat fAngle, void* pUserCxt) {
        printf("swipe down, velocity: %f, angle: %f\n", fVelocity, fAngle);
        stringstream ss;
        ss << fVelocity * 100.0;
        send_event("rotate_down", ss.str().c_str());//fVelocity * 100.0);
	}
	
	// Push detector
	static void XN_CALLBACK_TYPE Push_Pushed(XnFloat fVelocity, XnFloat fAngle, void* cxt)
	{
        stringstream ss;
        ss << fVelocity * 100.0;
        printf("push, velocity: %f, angle: %f\n", fVelocity, fAngle);
        send_event("push", ss.str().c_str());//fVelocity * 100.0);	}
    }
	
	static void XN_CALLBACK_TYPE ACircle(XnFloat fTimes, XnBool bConfident, const XnVCircle* pCircle, void* cxt) {
		if(bConfident) {
            printf("fTimes %f" , fTimes);
            if(fTimes == 0)
            {
                printf("Got a circle!\n");
            }
			//printf("Bye Bye Circle!\n");
            
			//((HandPointControl*)cxt)->KillSession();
		}
	}

	// Wave detector
	static void XN_CALLBACK_TYPE Wave_Waved(void* cxt)
	{
		//printf("Bye Bye Wave!\n");
		//((HandPointControl*)cxt)->KillSession();
	}
	
	void KillSession() { m_SessionManager->EndSession(); }
	
	/**
	 * Handle creation of a new point
	 */
	void OnPointCreate(const XnVHandPointContext* cxt) {
				//send_event("Register", "");
        numHands++; 
        printf("** New hand detected -> total # of hands on screen is now %d, starting session %d\n", numHands, cxt->nID);	
        int numHandsToSend = numHands >= 2 ? 2 : numHands;
        stringstream ss;
        ss << numHandsToSend;
        send_event("register", ss.str().c_str());

	}
	
	/**
	 * Handle new position of an existing point
	 */
	void OnPointUpdate(const XnVHandPointContext* cxt) {
		// positions are kept in projective coordinates, since they are only used for drawing
		XnPoint3D ptProjective(cxt->ptPosition);
		
//		printf("Point (%f,%f,%f)", ptProjective.X, ptProjective.Y, ptProjective.Z);
		m_DepthGenerator.ConvertRealWorldToProjective(1, &ptProjective, &ptProjective);
//		printf(" -> (%f,%f,%f)\n", ptProjective.X, ptProjective.Y, ptProjective.Z);
		
		//move to [0->100,0->100,0->2048]
		stringstream ss;
		/*ss  << "\"x\":"  << (int)(100.0*ptProjective.X/640.0)
			<< ",\"y\":" << (int)(100.0*ptProjective.Y/480.0)
			<< ",\"z\":" << (int)ptProjective.Z;*/
        
        ss  << ""  << (int)(ptProjective.Y) //no y scaling is needed
        << "," << (int)(100*ptProjective.X/150.0) //scale x by 33%
        << "," << (int)(0);//ptProjective.Z); //TODO: fix depth movement
		//cout << "move: " << ss.str() << endl;
        //printf("Move: %s\n", ss.str().c_str());
		send_event("move", ss.str().c_str());		
	}	
	
	/**
	 * Handle destruction of an existing point
	 */
	void OnPointDestroy(XnUInt32 nID) {
		
        numHands--;
        printf("** Lost hand with session ID %d -> total # of hands on screen is now %d\n", nID, numHands);
        int numHandsToSend = numHands >= 2 ? 2 : numHands;
        stringstream ss;
        ss << numHandsToSend;
        send_event("register", ss.str().c_str());
		//send_event("Unregister", "");
	}

private:
	xn::DepthGenerator m_DepthGenerator;
	XnVSessionManager* m_SessionManager;
	
//	XnVBroadcaster m_Broadcaster;
	XnVPushDetector* m_pPushDetector;
	XnVSwipeDetector* m_pSwipeDetector;
//	XnVSteadyDetector* m_pSteadyDetector;		
//	XnVFlowRouter* m_pInnerFlowRouter;
//	
//	XnVWaveDetector* m_pWaveDetector;
	XnVCircleDetector* m_pCircleDetector;
    int numHands;
};

#endif