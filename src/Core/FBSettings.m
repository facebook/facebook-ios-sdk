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

#import "FBSettings.h"
#import "FBSettings+Internal.h"

#import <UIKit/UIKit.h>

#import "FBError.h"
#import "FBLogger.h"
#import "FBRequest.h"
#import "FBSession+Internal.h"
#import "FBUtility.h"
#import "FacebookSDK.h"

// Keys to get App-specific info from mainBundle
static NSString *const FBPLISTDisplayNameKey = @"FacebookDisplayName";
static NSString *const FBPLISTAppIDKey = @"FacebookAppID";
NSString *const FBPLISTUrlSchemeSuffixKey = @"FacebookUrlSchemeSuffix";
static NSString *const FBPLISTBundleNameKey = @"FacebookBundleName";

// const strings
NSString *const FBLoggingBehaviorFBRequests = @"fb_requests";
NSString *const FBLoggingBehaviorFBURLConnections = @"fburl_connections";
NSString *const FBLoggingBehaviorAccessTokens = @"include_access_tokens";
NSString *const FBLoggingBehaviorSessionStateTransitions = @"state_transitions";
NSString *const FBLoggingBehaviorPerformanceCharacteristics = @"perf_characteristics";
NSString *const FBLoggingBehaviorAppEvents = @"app_events";
NSString *const FBLoggingBehaviorInformational = @"informational";
NSString *const FBLoggingBehaviorDeveloperErrors = @"developer_errors";

NSString *const FBLastAttributionPing = @"com.facebook.sdk:lastAttributionPing%@";
NSString *const FBLastInstallResponse = @"com.facebook.sdk:lastInstallResponse%@";
NSString *const FBSettingsLimitEventAndDataUsage = @"com.facebook.sdk:FBAppEventsLimitEventUsage";  // use "FBAppEvents" in string due to previous place this lived.

NSString *const FBPublishActivityPath = @"%@/activities";
NSString *const FBMobileInstallEvent = @"MOBILE_APP_INSTALL";

NSTimeInterval const FBPublishDelay = 0.1;

@implementation FBSettings

static NSSet *g_loggingBehavior;
static BOOL g_autoPublishInstall = YES;
static dispatch_once_t g_publishInstallOnceToken;
static NSString *g_appVersion;
static NSString *g_clientToken;
static NSString *g_defaultDisplayName = nil;
static NSString *g_defaultAppID = nil;
static NSString *g_defaultUrlSchemeSuffix = nil;
static NSString *g_defaultBundleName = nil;
static NSString *g_defaultFacebookDomainPart = nil;
static CGFloat g_defaultJPEGCompressionQuality = 0.9;
static NSUInteger g_betaFeatures = 0;
static FBRestrictedTreatment g_restrictedTreatment;

+ (NSString *)sdkVersion {
    return FB_IOS_SDK_VERSION_STRING;
}

+ (NSSet *)loggingBehavior {
    if (!g_loggingBehavior) {

        // Establish set of default enabled logging behaviors.  Can completely disable logging by
        // calling setLoggingBehavior with an empty set.
        g_loggingBehavior = [[NSSet setWithObject:FBLoggingBehaviorDeveloperErrors] retain];
    }
    return g_loggingBehavior;
}

+ (void)setLoggingBehavior:(NSSet *)newValue {
    [newValue retain];
    [g_loggingBehavior release];
    g_loggingBehavior = newValue;
}

+ (NSString *)appVersion {
    return g_appVersion;
}

+ (void)setAppVersion:(NSString *)appVersion {
    [appVersion retain];
    [g_appVersion release];
    g_appVersion = appVersion;
}

+ (NSString *)clientToken {
    return g_clientToken;
}

+ (void)setClientToken:(NSString *)clientToken {
    [clientToken retain];
    [g_clientToken release];
    g_clientToken = clientToken;
}

+ (void)setDefaultDisplayName:(NSString *)displayName {
    NSString *oldValue = g_defaultDisplayName;
    g_defaultDisplayName = [displayName copy];
    [oldValue release];
}

+ (NSString *)defaultDisplayName {
    if (!g_defaultDisplayName) {
        NSBundle *bundle = [NSBundle mainBundle];
        g_defaultDisplayName = [bundle objectForInfoDictionaryKey:FBPLISTDisplayNameKey];
    }
    return g_defaultDisplayName;
}

+ (void)setrestrictedTreatment:(FBRestrictedTreatment)treatment {
    g_restrictedTreatment = treatment;
    if (treatment == FBRestrictedTreatmentYES && [FBSession activeSessionIfOpen]) {
        [FBSession.activeSession close];
    }
}

+ (FBRestrictedTreatment)restrictedTreatment {
    return g_restrictedTreatment;
}

+ (void)setDefaultAppID:(NSString *)appID {
    NSString *oldValue = g_defaultAppID;
    g_defaultAppID = [appID copy];
    [oldValue release];
}

+ (NSString *)defaultAppID {
    if (!g_defaultAppID) {
        NSBundle *bundle = [NSBundle mainBundle];
        g_defaultAppID = [bundle objectForInfoDictionaryKey:FBPLISTAppIDKey];
    }
    return g_defaultAppID;
}

+ (void)setResourceBundleName:(NSString *)bundleName {
    NSString *oldValue = g_defaultBundleName;
    g_defaultBundleName = [bundleName copy];
    [oldValue release];
}

+ (NSString *)resourceBundleName {
    if (!g_defaultBundleName) {
        NSBundle *bundle = [NSBundle mainBundle];
        g_defaultBundleName = [bundle objectForInfoDictionaryKey:FBPLISTBundleNameKey];
#if TARGET_IPHONE_SIMULATOR
        // The FacebookSDKResources.bundle is no longer used.
        // Warn the developer if they are including it by default
        if (![g_defaultBundleName isEqualToString:@"FacebookSDKResources"]) {
            NSString *facebookSDKBundlePath = [bundle pathForResource:@"FacebookSDKResources" ofType:@"bundle"];
            if (facebookSDKBundlePath) {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:@"The FacebookSDKResources.bundle is no longer required for your application.  It can be removed.  After fixing this, you will need to Clean the project and then reset your simulator."];
            }
        }
#endif
    }
    return g_defaultBundleName;
}

+ (void)setFacebookDomainPart:(NSString *)facebookDomainPart
{
    NSString *oldValue = g_defaultFacebookDomainPart;
    g_defaultFacebookDomainPart = [facebookDomainPart copy];
    [oldValue release];
}

+ (NSString *)facebookDomainPart {
    return g_defaultFacebookDomainPart;
}

+ (void)setDefaultUrlSchemeSuffix:(NSString *)urlSchemeSuffix {
    NSString *oldValue = g_defaultUrlSchemeSuffix;
    g_defaultUrlSchemeSuffix = [urlSchemeSuffix copy];
    [oldValue release];
}

+ (NSString *)defaultUrlSchemeSuffix {
    if (!g_defaultUrlSchemeSuffix) {
        NSBundle *bundle = [NSBundle mainBundle];
        g_defaultUrlSchemeSuffix = [bundle objectForInfoDictionaryKey:FBPLISTUrlSchemeSuffixKey];
    }
    return g_defaultUrlSchemeSuffix;
}

+ (NSString *)defaultURLSchemeWithAppID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    return [NSString stringWithFormat:@"fb%@%@", appID ?: [self defaultAppID], urlSchemeSuffix ?: [self defaultUrlSchemeSuffix] ?: @""];
}

+ (void)setdefaultJPEGCompressionQuality:(CGFloat)compressionQuality {
    g_defaultJPEGCompressionQuality = compressionQuality;
}

+ (CGFloat)defaultJPEGCompressionQuality {
    return g_defaultJPEGCompressionQuality;
}

+ (BOOL)shouldAutoPublishInstall {
    return g_autoPublishInstall;
}

+ (void)setShouldAutoPublishInstall:(BOOL)newValue {
    g_autoPublishInstall = newValue;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
+ (void)autoPublishInstall:(NSString *)appID {
    if ([FBSettings shouldAutoPublishInstall]) {
        dispatch_once(&g_publishInstallOnceToken, ^{
            // dispatch_once is great, but not re-entrant.  Inside publishInstall we use FBRequest, which will
            // cause this function to get invoked a second time.  By scheduling the work, we can sidestep the problem.
            [[FBSettings class] performSelector:@selector(autoPublishInstallImpl:) withObject:appID afterDelay:FBPublishDelay];
        });
    }
}
#pragma GCC diagnostic pop

+ (void)autoPublishInstallImpl:(NSString *)appID {
    [FBSettings publishInstall:appID withHandler:nil isAutoPublish:YES];
}


+ (void)enableBetaFeatures:(NSUInteger)betaFeatures {
    g_betaFeatures |= betaFeatures;
}

+ (void)enableBetaFeature:(FBBetaFeatures)betaFeature {
    g_betaFeatures |= betaFeature;
}

+ (void)disableBetaFeature:(FBBetaFeatures)betaFeature {
    g_betaFeatures &= NSUIntegerMax ^ betaFeature;
}

+ (BOOL)isBetaFeatureEnabled:(FBBetaFeatures)betaFeature {
    return (g_betaFeatures & betaFeature) == betaFeature;
}

#pragma mark -
#pragma mark - Event usage

+ (BOOL)limitEventAndDataUsage {
    NSNumber *storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:FBSettingsLimitEventAndDataUsage];
    if (storedValue == nil) {
        return NO;
    }
    return storedValue.boolValue;
}

+ (void)setLimitEventAndDataUsage:(BOOL)limitEventAndDataUsage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:limitEventAndDataUsage] forKey:FBSettingsLimitEventAndDataUsage];
    [defaults synchronize];
}

#pragma mark -
#pragma mark proto-activity publishing code

+ (void)publishInstall:(NSString *)appID {
    [FBSettings publishInstall:appID withHandler:nil];
}

+ (void)publishInstall:(NSString *)appID
           withHandler:(FBInstallResponseDataHandler)handler {
    [FBSettings publishInstall:appID withHandler:handler isAutoPublish:NO];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
+ (void)publishInstall:(NSString *)appID
           withHandler:(FBInstallResponseDataHandler)handler
         isAutoPublish:(BOOL)isAutoPublish {
    @try {
        handler = [[handler copy] autorelease];

        if (!appID) {
            appID = [FBSettings defaultAppID];
        }

        if (!appID) {
            // if the appID is still nil, exit early.
            if (handler) {
                handler(
                        nil,
                        [NSError errorWithDomain:FacebookSDKDomain
                                            code:FBErrorPublishInstallResponse
                                        userInfo:@{ NSLocalizedDescriptionKey : @"A valid App ID was not supplied or detected.  Please call with a valid App ID or configure the app correctly to include FB App ID."}]
                        );
            }
            return;
        }

        // We turn off auto-publish, since this was manually called and the expectation
        // is that it's only ever necessary to call this once.
        if (!isAutoPublish) {
            [FBSettings setShouldAutoPublishInstall:NO];
        }

        // look for a previous ping & grab the facebook app's current attribution id.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *pingKey = [NSString stringWithFormat:FBLastAttributionPing, appID, nil];
        NSString *responseKey = [NSString stringWithFormat:FBLastInstallResponse, appID, nil];

        NSDate *lastPing = [defaults objectForKey:pingKey];
        id lastResponseData = [defaults objectForKey:responseKey];

        NSString *attributionID = [FBUtility attributionID];
        NSString *advertiserID = [FBUtility advertiserID];

        if (lastPing) {
            // Short circuit
            if (handler) {
                handler(lastResponseData, nil);
            }
            return;
        }

        if (!(attributionID || advertiserID)) {
            if (handler) {
                handler(
                        nil,
                        [NSError errorWithDomain:FacebookSDKDomain
                                            code:FBErrorPublishInstallResponse
                                        userInfo:@{ NSLocalizedDescriptionKey : @"A valid attribution ID or advertiser ID was not found.  Publishing install when neither of them is present is a no-op."}]
                        );
            }
            return;
        }

        FBRequestHandler publishCompletionBlock = ^(FBRequestConnection *connection,
                                                    id result,
                                                    NSError *error) {
            @try {
                if (!error) {
                    // if server communication was successful, take note of the current time.
                    [defaults setObject:[NSDate date] forKey:pingKey];
                    [defaults setObject:result forKey:responseKey];
                    [defaults synchronize];
                } else {
                    // there was a problem.  allow a repeat execution.
                    g_publishInstallOnceToken = 0;
                }
            } @catch (NSException *ex1) {
                NSLog(@"Failure after install publish: %@", ex1.reason);
            }

            // Callback regardless of exception
            if (handler) {
                handler(result, error);
            }
        };

        [FBUtility fetchAppSettings:appID
                           callback:^(FBFetchedAppSettings *settings, NSError *error) {
                               if (!error) {
                                   @try {
                                       if (settings.supportsAttribution) {
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
                                           [FBUtility updateParametersWithEventUsageLimitsAndBundleInfo:installActivity];

                                           [installActivity setObject:[NSNumber numberWithBool:isAutoPublish].stringValue forKey:@"auto_publish"];

                                           FBRequest *publishRequest = [[[FBRequest alloc] initForPostWithSession:nil graphPath:publishPath graphObject:installActivity] autorelease];
                                           [publishRequest startWithCompletionHandler:publishCompletionBlock];
                                       } else {
                                           // the app has turned off install insights.  prevent future attempts.
                                           [defaults setObject:[NSDate date] forKey:pingKey];
                                           [defaults setObject:nil forKey:responseKey];
                                           [defaults synchronize];

                                           if (handler) {
                                               handler(
                                                       nil,
                                                       [NSError errorWithDomain:FacebookSDKDomain
                                                                           code:FBErrorPublishInstallResponse
                                                                       userInfo:@{ NSLocalizedDescriptionKey : @"The application has not enabled install insights.  To turn this on, go to developers.facebook.com and enable install insights for the app."}]
                                                       );
                                           }
                                       }
                                   } @catch (NSException *ex2) {
                                       NSString *errorMessage = [NSString stringWithFormat:@"Failure during install publish: %@", ex2.reason];
                                       NSLog(@"%@", errorMessage);
                                       if (handler) {
                                           handler(
                                                   nil,
                                                   [NSError errorWithDomain:FacebookSDKDomain
                                                                       code:FBErrorPublishInstallResponse
                                                                   userInfo:@{ NSLocalizedDescriptionKey : errorMessage}]
                                                   );
                                       }

                                   }
                               }
                           }];
    } @catch (NSException *ex3) {
        NSString *errorMessage = [NSString stringWithFormat:@"Failure before/during install ping: %@", ex3.reason];
        NSLog(@"%@", errorMessage);
        if (handler) {
            handler(
                    nil,
                    [NSError errorWithDomain:FacebookSDKDomain
                                        code:FBErrorPublishInstallResponse
                                    userInfo:@{ NSLocalizedDescriptionKey : errorMessage}]
                    );
        }
    }
}
#pragma GCC diagnostic pop

@end
