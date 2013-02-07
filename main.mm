//
//  main.cpp
//  webkit-plugin-mac
//
//  Created by Ben Katz on 10/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//#include <iostream>
#import <Cocoa/Cocoa.h>
#include "Lesson07Controller.h"
int main(int argc, const char *argv[])
{
    return NSApplicationMain(argc, argv);
}

void send_event(char* etype, const char* data) {
    receiveMsg(etype, data);
}