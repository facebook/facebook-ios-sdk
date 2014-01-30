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

#import "RPSAppDelegate.h"

#import <FacebookSDK/FacebookSDK.h>

#import "RPSCommonObjects.h"
#import "RPSDeeplyLinkedViewController.h"
#import "RPSFriendsViewController.h"
#import "RPSGameViewController.h"

@implementation RPSAppDelegate

#pragma mark - Class methods

+ (RPSCall)callFromAppLinkData:(FBAppLinkData *)appLinkData {
    NSString *fbObjectID = [appLinkData originalQueryParameters][@"fb_object_id"];

    if (fbObjectID == nil) {
        return RPSCallNone;
    }

    RPSCall call = RPSCallNone;
    NSInteger callOptionCount = sizeof(builtInOpenGraphObjects) / sizeof(builtInOpenGraphObjects[0]);
    for (RPSCall callIndex = 0; callIndex < callOptionCount; callIndex++) {
        if ([builtInOpenGraphObjects[callIndex] isEqualToString:fbObjectID]) {
            call = callIndex;
            break;
        }
    }

    if (call == RPSCallNone) {
        NSLog(@"Unexpected: deeplink was present, but did not contain a valid rock, paper or scissor fb_object_id");
    }
    return call;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                    fallbackHandler:^(FBAppCall *call) {
                        // Check for a deep link to parse out a call to show
                        RPSCall deepCall = [RPSAppDelegate callFromAppLinkData:[call appLinkData]];
                        if (deepCall != RPSCallNone) {
                            RPSDeeplyLinkedViewController *vc = [[RPSDeeplyLinkedViewController alloc] initWithCall:deepCall];
                            [self.navigationController presentViewController:vc animated:YES completion:nil];
                        }
                    }];
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
