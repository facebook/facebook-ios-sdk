/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "BOGAppDelegate.h"
#import "BOGFirstViewController.h"
#import "BOGSecondViewController.h"

@implementation BOGAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

// FBSample logic
// The native facebook application transitions back to an authenticating application when the user 
// chooses to either log in, or cancel. This call to handleOpenURL manages that transition. See the
// "Just Login" sample application for deeper discussion on this topic.
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url]; 
}

// FBSample logic
// Open session objects should be closed when no longer useful 
- (void)applicationWillTerminate:(UIApplication *)application {
    // all good things must come to an end
    // this is a good idea because things may be hanging off the session, that need 
    // releasing (completion block, etc.) and other components in the app may be awaiting
    // close notification in order to do cleanup
    [FBSession.activeSession close];
}

// FBSample logic
// The session management and login behavior of this sample is very simplistic; for deeper coverage of
// this topic see the "Just Login" or "Switch User" sample applicaitons
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    UIViewController *viewControllerMe, *viewControllerFriends;
    FBUserSettingsViewController *viewControllerSettings;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewControllerMe = [[BOGFirstViewController alloc] initWithNibName:@"BOGFirstViewController_iPhone" bundle:nil];
        viewControllerFriends = [[BOGSecondViewController alloc] initWithNibName:@"BOGSecondViewController_iPhone" bundle:nil];
    } else {
        viewControllerMe = [[BOGFirstViewController alloc] initWithNibName:@"BOGFirstViewController_iPad" bundle:nil];
        viewControllerFriends = [[BOGSecondViewController alloc] initWithNibName:@"BOGSecondViewController_iPad" bundle:nil];
    }
    viewControllerSettings = [[FBUserSettingsViewController alloc] init];
    viewControllerSettings.title = @"Facebook Settings";
    viewControllerSettings.tabBarItem.image = [UIImage imageNamed:@"second"];    
        
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:viewControllerMe, viewControllerFriends, viewControllerSettings, nil];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    // FBSample logic
    // We open the session up front, as long as we have a cached token, otherwise rely on the user 
    // to login explicitly with the FBUserSettingsViewController tab
    [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    return YES;
}

@end
