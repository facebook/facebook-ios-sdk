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

#import "FPAppDelegate.h"

#import "FPViewController.h"

@implementation FPAppDelegate

@synthesize window = _window;
@synthesize rootViewController = _rootViewController;

// FBSample logic
// In the login workflow, the Facebook native application, or Safari will transition back to
// this applicaiton via a url following the scheme fb[app id]://; the call to handleOpenURL
// below captures the token, in the case of success, on behalf of the FBSession object
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActive];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // If you have not added the -ObjC linker flag, you may need to uncomment the following line because
    // Nib files require the type to have been loaded before they can do the wireup successfully.
    // http://stackoverflow.com/questions/1725881/unknown-class-myclass-in-interface-builder-file-error-at-runtime
    // [FBFriendPickerViewController class];

    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.rootViewController = [[FPViewController alloc] initWithNibName:@"FPViewController_iPhone" bundle:nil];
    } else {
        self.rootViewController = [[FPViewController alloc] initWithNibName:@"FPViewController_iPad" bundle:nil];
    }
#ifdef __IPHONE_7_0
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if ([self.rootViewController respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.rootViewController.edgesForExtendedLayout &= ~UIRectEdgeTop;
    }
#endif
#endif
#endif
    self.rootViewController.navigationItem.title = @"Friend Picker";

    // Set up a UINavigationController as the basis of this app, with the nib generated viewController
    // as the initial view.
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:self.rootViewController];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

// FBSample logic
// It is important to close any FBSession object that is no longer useful
- (void)applicationWillTerminate:(UIApplication *)application {
    // Close the session before quitting
    // this is a good idea because things may be hanging off the session, that need
    // releasing (completion block, etc.) and other components in the app may be awaiting
    // close notification in order to do cleanup
    [FBSession.activeSession close];
}

@end
