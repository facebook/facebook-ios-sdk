//
//  JRAppDelegate.m
//  JustRequestSample
//
//  Created by Michael Marucheck on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <FBiOSSDK/FBSession.h>
#import "JRAppDelegate.h"
#import "JRViewController.h"

@implementation JRAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize session = _session;

#pragma mark Template generated code

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [self.session handleOpenURL:url];
}

- (void)dealloc
{
    [_session invalidate];

    [_window release];
    [_viewController release];
    [_session release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[[JRViewController alloc] initWithNibName:@"JRViewController_iPhone" bundle:nil] autorelease];
    } else {
        self.viewController = [[[JRViewController alloc] initWithNibName:@"JRViewController_iPad" bundle:nil] autorelease];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.session invalidate];
}

#pragma mark end Template generated code

@end
