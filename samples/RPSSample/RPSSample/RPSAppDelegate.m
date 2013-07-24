/*
 * Copyright 2010-present Facebook.
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

#import "RPSAppDelegate.h"
#import "RPSGameViewController.h"
#import "RPSFriendsViewController.h"

@implementation RPSAppDelegate

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // all good things must come to an end
    // this is a good idea because things may be hanging off the session, that need 
    // releasing (completion block, etc.) and other components in the app may be awaiting
    // close notification in order to do cleanup
    [FBSession.activeSession close];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
#ifdef DEBUG
    [FBSettings enableBetaFeature:FBBetaFeaturesOpenGraphShareDialog | FBBetaFeaturesShareDialog];
#endif
    UIViewController *viewControllerGame;
    FBUserSettingsViewController *viewControllerSettings;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewControllerGame = [[RPSGameViewController alloc] initWithNibName:@"RPSGameViewController_iPhone" bundle:nil];
    } else {
        viewControllerGame = [[RPSGameViewController alloc] initWithNibName:@"RPSGameViewController_iPad" bundle:nil];
    }
    viewControllerSettings = [[FBUserSettingsViewController alloc] init];
    viewControllerSettings.title = @"Facebook Settings";
    viewControllerSettings.tabBarItem.image = [UIImage imageNamed:@"second"];
        
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:viewControllerGame];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    return YES;
}

@end
