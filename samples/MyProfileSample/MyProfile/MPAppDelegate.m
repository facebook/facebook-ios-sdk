//
//  MPAppDelegate.m
//  MyProfile
//
//  Created by Greg Schechter on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MPAppDelegate.h"

#import "MPViewController.h"
#import <FBiOSSDK/FBProfilePictureView.h>

@interface MPAppDelegate ()
@end		  
		
@implementation MPAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize session = _session;


// FBSample logic
// if we have a valid session at the time of openURL call, we handle Facebook transitions
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // attempt to extract a token from the url
    return [self.session handleOpenURL:url]; 
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // FBSample logic
    // if the app is going away, we invalidate the token if present
    [self.session invalidate];
}

                
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // BUG:
    // Nib files require the type to have been loaded before they can do the
    // wireup successfully.  
    // http://stackoverflow.com/questions/1725881/unknown-class-myclass-in-interface-builder-file-error-at-runtime
    [FBProfilePictureView class];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[MPViewController alloc] initWithNibName:@"MPViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[MPViewController alloc] initWithNibName:@"MPViewController_iPad" bundle:nil];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}



@end
