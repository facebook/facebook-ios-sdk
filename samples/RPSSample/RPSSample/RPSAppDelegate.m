// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RPSAppDelegate.h"

#import <Bolts/Bolts.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "RPSAppLinkedViewController.h"
#import "RPSCommonObjects.h"
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

    BOOL result = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                 openURL:url
                                                       sourceApplication:sourceApplication
                                                              annotation:annotation];

    RPSCall appLinkCall = [RPSAppDelegate callFromAppLinkURL:url sourceApplication:sourceApplication];
    if (appLinkCall != RPSCallNone) {
        RPSAppLinkedViewController *vc = [[RPSAppLinkedViewController alloc] initWithCall:appLinkCall];
        [self.navigationController presentViewController:vc animated:YES completion:nil];
    }
    return result;
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

    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSDKAppEvents activateApp];
}

@end
