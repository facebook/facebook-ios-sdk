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

#import "SCAppDelegate.h"

#import <FacebookSDK/FacebookSDK.h>

#import "SCErrorHandler.h"
#import "SCSettings.h"

@implementation SCAppDelegate

#pragma mark - Class Methods

+ (void)initialize
{
    // Nib files require the type to have been loaded before they can do the wireup successfully.
    // http://stackoverflow.com/questions/1725881/unknown-class-myclass-in-interface-builder-file-error-at-runtime
    [FBLoginView class];
    [FBProfilePictureView class];
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Facebook SDK * pro-tip *
    // We take advantage of the `FBLoginView` in our loginViewController, which can
    // automatically open a session if there is a token cached. If we were not using
    // that control, this location would be a good place to try to open a session
    // from a token cache.

    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // Facebook SDK * login flow *
    // Attempt to handle URLs to complete any auth (e.g., SSO) flow.
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication fallbackHandler:^(FBAppCall *call) {
        // Since Scrumptious supports Single Sign On from the Facebook App (such as bookmarks),
        // we supply a fallback handler to parse any inbound URLs (e.g., deep links)
        // which can contain an access token.
        if (call.accessTokenData) {
            if ([FBSession activeSession].isOpen) {
                NSLog(@"INFO: Ignoring new access token because current session is open.");
            }
            else {
                [self _handleOpenURLWithAccessToken:call.accessTokenData];
            }
        }
    }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppEvents activateApp];

    // Facebook SDK * login flow *
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBAppCall handleDidBecomeActive];
}

#pragma mark - Helper Methods

- (void)_handleOpenURLWithAccessToken:(FBAccessTokenData *)token {
    // Initialize a new blank session instance...
    FBSession *sessionFromToken = [[FBSession alloc] initWithAppID:nil
                                                     permissions:nil
                                                 defaultAudience:FBSessionDefaultAudienceNone
                                                 urlSchemeSuffix:nil
                                              tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance] ];
    [FBSession setActiveSession:sessionFromToken];
    // ... and open it from the supplied token.
    [sessionFromToken openFromAccessTokenData:token
                          completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                              // Forward any errors to the FBLoginView delegate.
                              if (error) {
                                  SCHandleError(error);
                              }
                          }];
}

@end
