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

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet FBTMainViewController *controller;
@property (copy) Facebook *facebook;
@property (assign) BOOL loggedIn;

@end
