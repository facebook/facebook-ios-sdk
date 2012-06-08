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

#import <FBiOSSDK/FacebookSDK.h>
#import "SCAppDelegate.h"
#import "SCViewController.h"
#import "SCLoginViewController.h"

@interface SCAppDelegate ()

@property (strong, nonatomic) UINavigationController* navController;
@property (strong, nonatomic) SCViewController *mainViewController;

- (FBSession *)createNewSession;

@end

@implementation SCAppDelegate

@synthesize window = _window;
@synthesize mainViewController = _viewController;
@synthesize session = _session;
@synthesize navController = _navController;

#pragma mark -
#pragma mark Facebook Login Code

- (FBSession *)createNewSession
{
    NSArray *permissions = [NSArray arrayWithObjects:@"publish_actions", @"user_photos", nil];
    self.session = [[FBSession alloc] initWithPermissions:permissions];

    return self.session;
}

- (void)showLoginView 
{
    UIViewController *topViewController = [self.navController topViewController];
    UIViewController *modalViewController = [topViewController modalViewController];
    
    if (![modalViewController isKindOfClass:[SCLoginViewController class]]) {
        SCLoginViewController* loginViewController = [[SCLoginViewController alloc]initWithNibName:@"SCLoginViewController" 
                                                                                  bundle:nil];
        [topViewController presentModalViewController:loginViewController animated:NO];
    } else {
        SCLoginViewController* loginViewController = (SCLoginViewController*)modalViewController;
        [loginViewController loginFailed];
    }
}

- (void)sessionStateChanged:(FBSession *)session 
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            {
                UIViewController *topViewController = [self.navController topViewController];
                if ([[topViewController modalViewController] isKindOfClass:[SCLoginViewController class]]) {
                    [topViewController dismissModalViewControllerAnimated:YES];
                }
                
                // fetch and cache the friends for the friend picker as soon as possible
                FBCacheDescriptor *cacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
                [cacheDescriptor prefetchAndCacheForSession:session];
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            // Once the user has logged in, we want them to be looking at the root view.
            [self.navController popToRootViewControllerAnimated:NO];
            
            [session closeAndClearTokenInformation];
            self.session = nil;
            
            [self createNewSession];
            [self showLoginView];
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }    
}

- (void)openSession
{
    [self.session openWithCompletionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];    
}
- (void)closeSession
{
    [self.session closeAndClearTokenInformation];
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation 
{
    return [self.session handleOpenURL:url]; 
}

- (void)applicationDidBecomeActive:(UIApplication *)application	
{	
    // this means the user switched back to this app without completing a login in Safari/Facebook App
    if (self.session.state == FBSessionStateCreatedOpening) {	
        [self.session close]; // so we close our session and start over	
    }	
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // BUG WORKAROUND:
    // Nib files require the type to have been loaded before they can do the
    // wireup successfully.  
    // http://stackoverflow.com/questions/1725881/unknown-class-myclass-in-interface-builder-file-error-at-runtime
    [FBProfilePictureView class];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.mainViewController = [[SCViewController alloc] initWithNibName:@"SCViewController" bundle:nil];
    self.navController = [[UINavigationController alloc]initWithRootViewController:self.mainViewController];
    self.window.rootViewController = self.navController;
    
    [self.window makeKeyAndVisible];
    
    // Create an FBSession and see if it's got a token.
    [self createNewSession];
    if (self.session.state == FBSessionStateCreatedTokenLoaded) {
        // Yes, so just open the session (this won't display any UX).
        [self openSession];
    } else {
        // No, display the login page.
        [self showLoginView];
    }
    
    return YES;
}

@end
