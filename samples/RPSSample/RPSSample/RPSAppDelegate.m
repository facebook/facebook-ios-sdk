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

#import <Bolts/Bolts.h>

#import "RPSCommonObjects.h"
#import "RPSDeeplyLinkedViewController.h"
#import "RPSFriendsViewController.h"
#import "RPSGameViewController.h"

@implementation RPSAppDelegate

#pragma mark - Class methods

+ (RPSCall)callFromAppLinkURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    BFURL *appLinkURL = [BFURL URLWithInboundURL:url sourceApplication:sourceApplication];
    NSURL *appLinkTargetURL = [appLinkURL targetURL];
    if (!appLinkTargetURL) {
        return RPSCallNone;
    }
    NSString *queryString = [appLinkTargetURL query];
    for(NSString *component in [queryString componentsSeparatedByString:@"&"]) {
        NSArray *pair = [component componentsSeparatedByString:@"="];
        NSString *param = pair[0];
        NSString *val = pair[1];
        if ([param isEqualToString:@"gesture"]) {
            if ([val isEqualToString:@"rock"]) {
                return RPSCallRock;
            } else if ([val isEqualToString:@"paper"]) {
                return RPSCallPaper;
            } else if ([val isEqualToString:@"scissors"]) {
                return RPSCallScissors;
            }
        }
    }

    return RPSCallNone;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                    fallbackHandler:^(FBAppCall *call) {
                        // Check for an app link to parse out a call to show
                        RPSCall appLinkCall = [RPSAppDelegate callFromAppLinkURL:url sourceApplication:sourceApplication];
                        if (appLinkCall != RPSCallNone) {
                            RPSDeeplyLinkedViewController *vc = [[RPSDeeplyLinkedViewController alloc] initWithCall:appLinkCall];
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

    UIViewController *viewControllerGame;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewControllerGame = [[RPSGameViewController alloc] initWithNibName:@"RPSGameViewController_iPhone" bundle:nil];
    } else {
        viewControllerGame = [[RPSGameViewController alloc] initWithNibName:@"RPSGameViewController_iPad" bundle:nil];
    }
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:viewControllerGame];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    [FBSession openActiveSessionWithAllowLoginUI:NO];

    return YES;
}

@end
