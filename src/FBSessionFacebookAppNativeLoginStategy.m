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

#import "FBSessionFacebookAppNativeLoginStategy.h"

#import "FBLogger.h"
#import "FBSession+Internal.h"
#import "FBSessionAuthLogger.h"
#import "FBSessionLoginStrategy.h"
#import "FBUtility.h"

@implementation FBSessionFacebookAppNativeLoginStategy

- (BOOL)tryPerformAuthorizeWithParams:(FBSessionLoginStrategyParams *)params session:(FBSession *)session logger:(FBSessionAuthLogger *)logger {
    if (params.tryFBAppAuth) {
        FBFetchedAppSettings *fetchedSettings = [FBUtility fetchedAppSettings];
        [logger addExtrasForNextEvent:@{
                                        @"hasFetchedAppSettings": @(fetchedSettings != nil),
                                        @"pListFacebookDisplayName": [FBSettings defaultDisplayName] ?: @"<missing>"
                                        }];
        if ([FBSettings defaultDisplayName] &&            // don't autoselect Native Login unless the app has been setup for it,
            [session.appID isEqualToString:[FBSettings defaultAppID]] && // If the appId has been overridden, then the bridge cannot be used and native login is denied
            (fetchedSettings || params.canFetchAppSettings) &&   // and we have app-settings available to us, or could fetch if needed
            !TEST_DISABLE_FACEBOOKNATIVELOGIN) {
            if (!fetchedSettings) {
                // fetch the settings and call the session auth method again.
                [FBUtility fetchAppSettings:[FBSettings defaultAppID] callback:^(FBFetchedAppSettings *settings, NSError *error) {
                    [session retryableAuthorizeWithPermissions:params.permissions
                                               defaultAudience:params.defaultAudience
                                                integratedAuth:params.tryIntegratedAuth
                                                     FBAppAuth:params.tryFBAppAuth
                                                    safariAuth:params.trySafariAuth
                                                      fallback:params.tryFallback
                                                 isReauthorize:params.isReauthorize
                                           canFetchAppSettings:NO];
                }];
                return YES;
            } else {
                [logger addExtrasForNextEvent:@{
                                                @"suppressNativeGdp": @(fetchedSettings.suppressNativeGdp),
                                                @"serverAppName": fetchedSettings.serverAppName ?: @"<missing>"
                                                }];
                if (!fetchedSettings.suppressNativeGdp) {
                    if (![[FBSettings defaultDisplayName] isEqualToString:fetchedSettings.serverAppName]) {
                        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                            logEntry:@"PLIST entry for FacebookDisplayName does not match Facebook app name."];
                        [logger addExtrasForNextEvent:@{
                                                        @"nameMismatch": @(YES)
                                                        }];
                    }

                    NSDictionary *clientState = @{FBSessionAuthLoggerParamAuthMethodKey: self.methodName,
                                                  FBSessionAuthLoggerParamIDKey : logger.ID ?: @""};

                    FBAppCall *call = [session authorizeUsingFacebookNativeLoginWithPermissions:params.permissions
                                                                                defaultAudience:params.defaultAudience
                                                                                    clientState:clientState];
                    if (call) {
                        [logger addExtrasForNextEvent:@{
                                                        @"native_auth_appcall_id":call.ID
                                                        }];

                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (NSString *)methodName {
    return FBSessionAuthLoggerAuthMethodFBApplicationNative;
}

@end
