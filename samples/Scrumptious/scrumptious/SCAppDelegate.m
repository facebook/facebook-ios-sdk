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

#import "SCAppDelegate.h"
#import "SCViewController.h"
#import "SCLoginViewController.h"

NSString *const SCSessionStateChangedNotification = @"com.facebook.Scrumptious:SCSessionStateChangedNotification";

@interface SCAppDelegate ()

@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) SCViewController *mainViewController;
@property (strong, nonatomic) SCLoginViewController* loginViewController;

- (void)showLoginView;

@end

@implementation SCAppDelegate

@synthesize window = _window;
@synthesize mainViewController = _mainViewController;
@synthesize navController = _navController;
@synthesize loginViewController = _loginViewController;

#pragma mark -
#pragma mark Facebook Login Code

- (void)createAndPresentLoginView {
    if (self.loginViewController == nil) {
        self.loginViewController = [[SCLoginViewController alloc] initWithNibName:@"SCLoginViewController"
                                                                           bundle:nil];
        UIViewController *topViewController = [self.navController topViewController];
        [topViewController presentModalViewController:self.loginViewController animated:NO];
    }
}

- (void)showLoginView {
    if (self.loginViewController == nil) {
        [self createAndPresentLoginView];
    } else {
        [self.loginViewController loginFailed];
    }
}

- (void)sessionStateChanged:(FBSession *)session 
                      state:(FBSessionState)state
                      error:(NSError *)error
{
    // FBSample logic
    // Any time the session is closed, we want to display the login controller (the user
    // cannot use the application unless they are logged in to Facebook). When the session
    // is opened successfully, hide the login controller and show the main UI.
    switch (state) {
        case FBSessionStateOpen: {
                [self.mainViewController startLocationManager];
                if (self.loginViewController != nil) {
                    UIViewController *topViewController = [self.navController topViewController];
                    [topViewController dismissModalViewControllerAnimated:YES];
                    self.loginViewController = nil;
                }

                // FBSample logic
                // Pre-fetch and cache the friends for the friend picker as soon as possible to improve
                // responsiveness when the user tags their friends.
                FBCacheDescriptor *cacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
                [cacheDescriptor prefetchAndCacheForSession:session];
            }
            break;
        case FBSessionStateClosed: {
                // FBSample logic
                // Once the user has logged out, we want them to be looking at the root view.
                UIViewController *topViewController = [self.navController topViewController];
                UIViewController *modalViewController = [topViewController modalViewController];
                if (modalViewController != nil) {
                    [topViewController dismissModalViewControllerAnimated:NO];
                }
                [self.navController popToRootViewControllerAnimated:NO];
                
                [FBSession.activeSession closeAndClearTokenInformation];
            
                [self performSelector:@selector(showLoginView)
                       withObject:nil
                       afterDelay:0.5f];
            }
            break;
        case FBSessionStateClosedLoginFailed: {
                // if the token goes invalid we want to switch right back to
                // the login view, however we do it with a slight delay in order to
                // account for a race between this and the login view dissappearing
                // a moment before
                [self performSelector:@selector(showLoginView)
                           withObject:nil
                           afterDelay:0.5f];
            }
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SCSessionStateChangedNotification 
                                                        object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error: %@",
                                                                     [SCAppDelegate FBErrorCodeDescription:error.code]]
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }    
}

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    return [FBSession openActiveSessionWithReadPermissions:nil
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                             [self sessionStateChanged:session state:state error:error];
                                     }];    
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation {
    // FBSample logic
    // We need to handle URLs by passing them to FBSession in order for SSO authentication
    // to work.
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // FBSample logic
    // if the app is going away, we close the session object; this is a good idea because
    // things may be hanging off the session, that need releasing (completion block, etc.) and
    // other components in the app may be awaiting close notification in order to do cleanup
    [FBSession.activeSession close];
}

- (void)applicationDidBecomeActive:(UIApplication *)application	{
    // FBSample logic
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
    
    // FBSample logic
    // See if we have a valid token for the current state.
    if (![self openSessionWithAllowLoginUI:NO]) {
        // No? Display the login page.
        [self showLoginView];
    }
    
    return YES;
}

+ (NSString *)FBErrorCodeDescription:(FBErrorCode) code {
    switch(code){
        case FBErrorInvalid :{
            return @"FBErrorInvalid";
        }
        case FBErrorOperationCancelled:{
            return @"FBErrorOperationCancelled";
        }
        case FBErrorLoginFailedOrCancelled:{
            return @"FBErrorLoginFailedOrCancelled";
        }
        case FBErrorRequestConnectionApi:{
            return @"FBErrorRequestConnectionApi";
        }case FBErrorProtocolMismatch:{
            return @"FBErrorProtocolMismatch";
        }
        case FBErrorHTTPError:{
            return @"FBErrorHTTPError";
        }
        case FBErrorNonTextMimeTypeReturned:{
            return @"FBErrorNonTextMimeTypeReturned";
        }
        case FBErrorNativeDialog:{
            return @"FBErrorNativeDialog";
        }
        default:
            return @"[Unknown]";
    }
}

@end
