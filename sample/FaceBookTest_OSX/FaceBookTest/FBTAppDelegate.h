//
//  FBTAppDelegate.h
//  FaceBookTest
//
//  Created by David Bitton on 3/12/12.
//  Copyright (c) 2012 Code No Evil LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBTMainViewController.h"
#import <FacebookOSXSDK/FBConnect.h>

@interface FBTAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet FBTMainViewController *controller;
@property (copy) Facebook *facebook;
@property (assign) BOOL loggedIn;

@end
