//
//  FBTAppDelegate.h
//  FaceBookTest
//
//  Created by David Bitton on 3/12/12.
//  Copyright (c) 2012 Code No Evil LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBTMainViewController.h"
#import "FBConnect.h"

@interface FBTAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet FBTMainViewController *controller;
@property (retain) Facebook *facebook;
@property (assign) BOOL loggedIn;

@end
