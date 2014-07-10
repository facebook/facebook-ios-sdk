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

#import "FBSettings+Internal.h"

#import <UIKit/UIKit.h>

#import "FBAmbientDeviceInfo.h"
#import "FBBoltsMeasurementEventListener.h"
#import "FBError.h"
#import "FBInternalSettings.h"
#import "FBLogger.h"
#import "FBRequest.h"
#import "FBSession+Internal.h"
#import "FBUtility.h"
#import "FacebookSDK.h"

// Keys to get App-specific info from mainBundle
static NSString *const FBPLISTAppIDKey = @"FacebookAppID";
static NSString *const FBPLISTAppVersionKey = @"FacebookAppVersion";
static NSString *const FBPLISTClientTokenKey = @"FacebookClientToken";
static NSString *const FBPLISTDisplayNameKey = @"FacebookDisplayName";
static NSString *const FBPLISTDomainPartKey = @"FacebookDomainPart";
static NSString *const FBPLISTLoggingBehaviorKey = @"FacebookLoggingBehavior";
static NSString *const FBPLISTResourceBundleNameKey = @"FacebookBundleName";
NSString *const FBPLISTUrlSchemeSuffixKey = @"FacebookUrlSchemeSuffix";

// const strings
NSString *const FBLoggingBehaviorFBRequests = @"fb_requests";
NSString *const FBLoggingBehaviorFBURLConnections = @"fburl_connections";
NSString *const FBLoggingBehaviorAccessTokens = @"include_access_tokens";
NSString *const FBLoggingBehaviorSessionStateTransitions = @"state_transitions";
NSString *const FBLoggingBehaviorPerformanceCharacteristics = @"perf_characteristics";
NSString *const FBLoggingBehaviorAppEvents = @"app_events";
NSString *const FBLoggingBehaviorInformational = @"informational";
NSString *const FBLoggingBehaviorCacheErrors = @"cache_errors";
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
static NSUInteger g_betaFeatures = 0;
static NSString *g_clientToken;
static NSString *g_defaultDisplayName = nil;
static NSString *g_defaultAppID = nil;
static CGFloat g_defaultJPEGCompressionQuality = 0.9;
static NSString *g_defaultUrlSchemeSuffix = nil;
static NSString *g_facebookDomainPart = nil;
static NSString *g_resourceBundleName = nil;
static FBRestrictedTreatment g_restrictedTreatment;
static BOOL g_enableLegacyGraphAPI = NO;


+ (void)load {
    // when the app becomes active by any mean,  kick off the initialization.
    __block __weak id initializeObserver;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    initializeObserver = [center addObserverForName:UIApplicationDidBecomeActiveNotification
                                             object:nil
                                              queue:nil
                                         usingBlock:^(NSNotification *note) {
                                             [self FBSDKInitialize];
                                             // de-register the observer after initialization is done.
                                             [center removeObserver:initializeObserver];
                                         }];
}

// Initialize SDK settings.
// Don't call this function in any place else. It has been called when the class is loaded.
+ (void)FBSDKInitialize {
    static dispatch_once_t sdkConfigDone = 0;
    dispatch_once(&sdkConfigDone, ^{
        [FBBoltsMeasurementEventListener defaultListener];
    });
}

+ (NSString *)sdkVersion {
    return FB_IOS_SDK_VERSION_STRING;
}

+ (BOOL)isPlatformCompatibilityEnabled {
    return g_enableLegacyGraphAPI;
}

+ (void)enablePlatformCompatibility:(BOOL)enable {
    if (enable != g_enableLegacyGraphAPI) {
        g_enableLegacyGraphAPI = enable;
    }
}

+ (NSString *)platformVersion {
    if ([[self class] isPlatformCompatibilityEnabled]) {
        return @"v1.0";
    } else {
        return FB_IOS_SDK_TARGET_PLATFORM_VERSION;
    }
}

+ (NSString *)appVersion {
    if (!g_appVersion) {
        g_appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTAppVersionKey] copy];
    }
    return g_appVersion;
}

+ (void)setAppVersion:(NSString *)appVersion {
    if (![g_appVersion isEqualToString:appVersion]) {
        [g_appVersion release];
        g_appVersion = [appVersion copy];
    }
}

+ (NSString *)clientToken {
    if (!g_clientToken) {
        g_clientToken = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTClientTokenKey] copy];
    }
    return g_clientToken;
}

+ (void)setClientToken:(NSString *)clientToken {
    if (![g_clientToken isEqualToString:clientToken]) {
        [g_clientToken release];
        g_clientToken = [clientToken copy];
    }
}

+ (NSString *)defaultAppID {
    if (!g_defaultAppID) {
        g_defaultAppID = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTAppIDKey] copy];
    }
    return g_defaultAppID;
}

+ (void)setDefaultAppID:(NSString *)appID {
    if (![g_defaultAppID isEqualToString:appID]) {
        [g_defaultAppID release];
        g_defaultAppID = [appID copy];
    }
}

+ (NSString *)defaultDisplayName {
    if (!g_defaultDisplayName) {
        g_defaultDisplayName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTDisplayNameKey] copy];
    }
    return g_defaultDisplayName;
}

+ (void)setDefaultDisplayName:(NSString *)displayName {
    if (![g_defaultDisplayName isEqualToString:displayName]) {
        [g_defaultDisplayName release];
        g_defaultDisplayName = [displayName copy];
    }
}

+ (CGFloat)defaultJPEGCompressionQuality {
    return g_defaultJPEGCompressionQuality;
}

+ (void)setdefaultJPEGCompressionQuality:(CGFloat)compressionQuality {
    g_defaultJPEGCompressionQuality = compressionQuality;
}

+ (NSString *)defaultUrlSchemeSuffix {
    if (!g_defaultUrlSchemeSuffix) {
        g_defaultUrlSchemeSuffix = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTUrlSchemeSuffixKey] copy];
    }
    return g_defaultUrlSchemeSuffix;
}

+ (void)setDefaultUrlSchemeSuffix:(NSString *)urlSchemeSuffix {
    if (![g_defaultUrlSchemeSuffix isEqualToString:urlSchemeSuffix]) {
        [g_defaultUrlSchemeSuffix release];
        g_defaultUrlSchemeSuffix = [urlSchemeSuffix copy];
    }
}

+ (NSString *)facebookDomainPart {
    if (!g_facebookDomainPart) {
        g_facebookDomainPart = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTDomainPartKey] copy];
    }
    return g_facebookDomainPart;
}

+ (void)setFacebookDomainPart:(NSString *)facebookDomainPart
{
    if (![g_facebookDomainPart isEqualToString:facebookDomainPart]) {
        [g_facebookDomainPart release];
        g_facebookDomainPart = [facebookDomainPart copy];
    }
}

+ (NSSet *)loggingBehavior {
    if (!g_loggingBehavior) {
        NSArray *bundleLoggingBehaviors = [[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTLoggingBehaviorKey];
        if (bundleLoggingBehaviors) {
            g_loggingBehavior = [[NSSet alloc] initWithArray:bundleLoggingBehaviors];
        } else {
            // Establish set of default enabled logging behaviors.  You can completely disable logging by
            // specifying an empty array for FacebookLoggingBehavior in your Info.plist.
            g_loggingBehavior = [[NSSet alloc] initWithObjects:FBLoggingBehaviorDeveloperErrors, nil];
        }
    }
    return g_loggingBehavior;
}

+ (void)setLoggingBehavior:(NSSet *)loggingBehavior {
    if (![g_loggingBehavior isEqualToSet:loggingBehavior]) {
        [g_loggingBehavior release];
        g_loggingBehavior = [loggingBehavior copy];
    }
}

+ (NSString *)resourceBundleName {
    if (!g_resourceBundleName) {
        NSBundle *bundle = [NSBundle mainBundle];
        g_resourceBundleName = [[bundle objectForInfoDictionaryKey:FBPLISTResourceBundleNameKey] copy];
#if TARGET_IPHONE_SIMULATOR
        // The FacebookSDKResources.bundle is no longer used.
        // Warn the developer if they are including it by default
        if (![g_resourceBundleName isEqualToString:@"FacebookSDKResources"]) {
            NSString *facebookSDKBundlePath = [bundle pathForResource:@"FacebookSDKResources" ofType:@"bundle"];
            if (facebookSDKBundlePath) {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:@"The FacebookSDKResources.bundle is no longer required for your application.  It can be removed.  After fixing this, you will need to Clean the project and then reset your simulator."];
            }
        }
#endif
    }
    return g_resourceBundleName;
}

+ (void)setResourceBundleName:(NSString *)bundleName {
    if (![g_resourceBundleName isEqualToString:bundleName]) {
        [g_resourceBundleName release];
        g_resourceBundleName = [bundleName copy];
    }
}

+ (FBRestrictedTreatment)restrictedTreatment {
    return g_restrictedTreatment;
}

+ (void)setRestrictedTreatment:(FBRestrictedTreatment)treatment {
    g_restrictedTreatment = treatment;
    if (treatment == FBRestrictedTreatmentYES && [FBSession activeSessionIfOpen]) {
        [FBSession.activeSession close];
    }
}

+ (BOOL)shouldAutoPublishInstall {
    return g_autoPublishInstall;
}

+ (void)setShouldAutoPublishInstall:(BOOL)newValue {
    g_autoPublishInstall = newValue;
}

+ (NSString *)defaultURLSchemeWithAppID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    return [NSString stringWithFormat:@"fb%@%@", appID ?: [self defaultAppID], urlSchemeSuffix ?: [self defaultUrlSchemeSuffix] ?: @""];
}

+ (void)autoPublishInstall:(NSString *)appID {
    if ([FBSettings shouldAutoPublishInstall]) {
        dispatch_once(&g_publishInstallOnceToken, ^{
            // dispatch_once is great, but not re-entrant.  Inside publishInstall we use FBRequest, which will
            // cause this function to get invoked a second time.  By scheduling the work, we can sidestep the problem.
            [[FBSettings class] performSelector:@selector(autoPublishInstallImpl:) withObject:appID afterDelay:FBPublishDelay];
        });
    }
}

+ (void)autoPublishInstallImpl:(NSString *)appID {
    [FBSettings publishInstall:appID isAutoPublish:YES];
}


+ (void)enableBetaFeatures:(NSUInteger)betaFeatures {
    g_betaFeatures |= betaFeatures;
}

+ (void)enableBetaFeature:(FBBetaFeatures)betaFeature {
    g_betaFeatures |= betaFeature;
}

+ (void)disableBetaFeature:(FBBetaFeatures)betaFeature {
    g_betaFeatures &= ~0 ^ betaFeature;
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
    [FBSettings publishInstall:appID isAutoPublish:NO];
}

+ (void)publishInstall:(NSString *)appID
         isAutoPublish:(BOOL)isAutoPublish {
    @try {
        if (!appID) {
            appID = [FBSettings defaultAppID];
        }

        if (!appID) {
            // if the appID is still nil, exit early.
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
        NSString *attributionID = [FBUtility attributionID];
        NSString *advertiserID = [FBUtility advertiserID];

        if (lastPing) {
            // Short circuit
            return;
        }

        if (!(attributionID || advertiserID)) {
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
                [FBLogger singleShotLogEntry:FBLoggingBehaviorInformational
                                formatString:@"Failure after install publish: %@", ex1.reason];
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
                                           [FBUtility extendDictionaryWithEventUsageLimitsAndUrlSchemes:installActivity accessAdvertisingTrackingStatus:YES];
                                           [FBAmbientDeviceInfo extendDictionaryWithDeviceInfo:installActivity];

                                           [installActivity setObject:[NSNumber numberWithBool:isAutoPublish].stringValue forKey:@"auto_publish"];

                                           FBRequest *publishRequest = [[[FBRequest alloc] initForPostWithSession:nil graphPath:publishPath graphObject:installActivity] autorelease];
                                           [publishRequest startWithCompletionHandler:publishCompletionBlock];
                                       } else {
                                           // the app has turned off install insights.  prevent future attempts.
                                           [defaults setObject:[NSDate date] forKey:pingKey];
                                           [defaults setObject:nil forKey:responseKey];
                                           [defaults synchronize];
                                       }
                                   } @catch (NSException *ex2) {
                                       NSString *errorMessage = [NSString stringWithFormat:@"Failure during install publish: %@", ex2.reason];
                                       [FBLogger singleShotLogEntry:FBLoggingBehaviorInformational logEntry:errorMessage];
                                   }
                               }
                           }];
    } @catch (NSException *ex3) {
        NSString *errorMessage = [NSString stringWithFormat:@"Failure before/during install ping: %@", ex3.reason];
        NSLog(@"%@", errorMessage);
    }
}

@end
