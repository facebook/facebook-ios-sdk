/*
 * Copyright 2010 Facebook
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

#import "FBRequest.h"
#import "FBSession.h"
#import "FBSettings.h"
#import "FBSettings+Internal.h"

#import <AdSupport/AdSupport.h>
#import <UIKit/UIKit.h>

NSString *const FBLoggingBehaviorFBRequests = @"fb_requests";
NSString *const FBLoggingBehaviorFBURLConnections = @"fburl_connections";
NSString *const FBLoggingBehaviorAccessTokens = @"include_access_tokens";
NSString *const FBLoggingBehaviorSessionStateTransitions = @"state_transitions";
NSString *const FBLoggingBehaviorPerformanceCharacteristics = @"perf_characteristics";

NSString *const FBLastAttributionPing = @"com.facebook.sdk:lastAttributionPing%@";
NSString *const FBSupportsAttributionPath = @"%@?fields=supports_attribution";
NSString *const FBPublishActivityPath = @"%@/activities";
NSString *const FBMobileInstallEvent = @"MOBILE_APP_INSTALL";
NSString *const FBAttributionPasteboard = @"fb_app_attribution";
NSString *const FBSupportsAttribution = @"supports_attribution";

NSTimeInterval const FBPublishDelay = 0.1;

@implementation FBSettings

static NSSet *g_loggingBehavior;
static BOOL g_autoPublishInstall = YES;
static dispatch_once_t g_publishInstallOnceToken;

+ (NSSet *)loggingBehavior {
    return g_loggingBehavior;
}

+ (void)setLoggingBehavior:(NSSet *)newValue {
    [newValue retain];
    [g_loggingBehavior release];
    g_loggingBehavior = newValue;
}

+ (BOOL)shouldAutoPublishInstall {
    return g_autoPublishInstall;
}

+ (void)setShouldAutoPublishInstall:(BOOL)newValue {
    g_autoPublishInstall = newValue;
}

+ (void)autoPublishInstall:(NSString *)appID {
    if ([FBSettings shouldAutoPublishInstall]) {
        dispatch_once(&g_publishInstallOnceToken, ^{
            // dispatch_once is great, but not re-entrant.  Inside publishInstall we use FBRequest, which will
            // cause this function to get invoked a second time.  By scheduling the work, we can sidestep the problem.
            [[FBSettings class] performSelector:@selector(publishInstall:) withObject:appID afterDelay:FBPublishDelay];
        });
    }
}


#pragma mark -
#pragma mark proto-activity publishing code

+ (void)publishInstall:(NSString *)appID {
    @try {
        if (!appID) {
            appID = [FBSession defaultAppID];
        }

        if (!appID) {
            // if the appID is still nil, exit early.
            return;
        }

        // look for a previous ping & grab the facebook app's current attribution id.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *pingKey = [NSString stringWithFormat:FBLastAttributionPing, appID, nil];
        NSDate *lastPing = [defaults objectForKey:pingKey];
        NSString *attributionID = [[UIPasteboard pasteboardWithName:FBAttributionPasteboard create:NO] string];
  
        NSString *advertiserID = nil;
        if ([ASIdentifierManager class]) {
            ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
            advertiserID = [[manager advertisingIdentifier] UUIDString];
        }
  
        if ((attributionID || advertiserID) && !lastPing) {
            FBRequestHandler publishCompletionBlock = ^(FBRequestConnection *connection,
                                                        id result,
                                                        NSError *error) {
                @try {
                    if (!error) {
                        // if server communication was successful, take note of the current time.
                        [defaults setObject:[NSDate date] forKey:pingKey];
                        [defaults synchronize];
                    } else {
                        // there was a problem.  allow a repeat execution.
                        g_publishInstallOnceToken = 0;
                    }
                } @catch (NSException *ex1) {
                    NSLog(@"Failure after install publish: %@", ex1.reason);
                }
            };

            FBRequestHandler pingCompletionBlock = ^(FBRequestConnection *connection,
                                                     id result,
                                                     NSError *error) {
                if (!error) {
                    @try {
                        if ([result respondsToSelector:@selector(objectForKey:)] &&
                            [[result objectForKey:FBSupportsAttribution] boolValue]) {
                            // set up the HTTP POST to publish the attribution ID.
                            NSString *publishPath = [NSString stringWithFormat:FBPublishActivityPath, appID, nil];
                            NSMutableDictionary<FBGraphObject> *installActivity = [FBGraphObject graphObject];
                            [installActivity setObject:FBMobileInstallEvent forKey:@"event"];
                  
                            if (attributionID) {
                                [installActivity setObject:attributionID forKey:@"attribution"];
                            }
                            if (advertiserID) {
                                [installActivity setObject:advertiserID forKey:@"advertiser_id"];
                            }

                            FBRequest *publishRequest = [[[FBRequest alloc] initForPostWithSession:nil graphPath:publishPath graphObject:installActivity] autorelease];
                            [publishRequest startWithCompletionHandler:publishCompletionBlock];
                        } else {
                            // the app has turned off install insights.  prevent future attempts.
                            [defaults setObject:[NSDate date] forKey:pingKey];
                            [defaults synchronize];
                        }
                    } @catch (NSException *ex2) {
                        NSLog(@"Failure during install publish: %@", ex2.reason);
                    }
                }
            };

            NSString *pingPath = [NSString stringWithFormat:FBSupportsAttributionPath, appID, nil];
            FBRequest *pingRequest = [[[FBRequest alloc] initWithSession:nil graphPath:pingPath] autorelease];
            [pingRequest startWithCompletionHandler:pingCompletionBlock];
        }
    } @catch (NSException *ex3) {
        NSLog(@"Failure before/during install ping: %@", ex3.reason);
    }
}

@end
