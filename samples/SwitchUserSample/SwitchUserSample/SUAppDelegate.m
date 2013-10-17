/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SUAppDelegate.h"

#import "SUSettingsViewController.h"
#import "SUUsingViewController.h"

@implementation SUAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize userManager = _userManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // FBSample logic
    // Creates an instance of the SUUserManager class, used to manage multiple user logins; note that this
    // application does not attempt to maintain multiple active users at once; however it does remember
    // multiple users that have at one time or another logged onto facebook from the application; at any one
    // time there is only a single active user
    self.userManager = [[SUUserManager alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    SUUsingViewController *viewController1;
    SUSettingsViewController *viewController2;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewController1 = [[SUUsingViewController alloc] initWithNibName:@"SUUsingViewController_iPhone" bundle:nil];
        viewController2 = [[SUSettingsViewController alloc] initWithNibName:@"SUSettingsViewController_iPhone" bundle:nil];
    } else {
        viewController1 = [[SUUsingViewController alloc] initWithNibName:@"SUUsingViewController_iPad" bundle:nil];
        viewController2 = [[SUSettingsViewController alloc] initWithNibName:@"SUSettingsViewController_iPad" bundle:nil];
    }
    viewController2.wantsFullScreenLayout = YES;
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:viewController1, viewController2, nil];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    // FBSample logic
    // At startup time we attempt to log in the default user that has signed on using Facebook Login
    [viewController2 loginDefaultUser];

    return YES;
}

// FBSample logic
// As part of the login workflow, the native application or Safari will transition back to this application'
// this method is then called, which defers the responsibility of parsing the url to the handleOpenURL method
// of FBSession
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:self.userManager.currentSession];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActiveWithSession:self.userManager.currentSession];
}

@end
