//
//  FBTAppDelegate.m
//  FaceBookTest
//
//  Created by David Bitton on 3/12/12.
//  Copyright (c) 2012 Code No Evil LLC. All rights reserved.
//

#import "FBTAppDelegate.h"
#import "FBTMainViewController.h"

// Your Facebook APP Id must be set before running this example
// See http://www.facebook.com/developers/createapp.php
static NSString* kAppId = @"210849718975311";

@implementation FBTAppDelegate

@synthesize window = _window;
@synthesize controller;
@synthesize facebook;
@synthesize loggedIn;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // Initialize Facebook
    facebook = [[Facebook alloc] initWithAppId:kAppId andDelegate:controller];
    
    // Check and retrieve authorization information
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
}



@end
