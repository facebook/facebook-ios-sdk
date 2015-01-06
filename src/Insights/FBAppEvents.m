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

#import "FBAppEvents.h"
#import "FBAppEvents+Internal.h"

#import <UIKit/UIApplication.h>

#import "FBError.h"
#import "FBLogger.h"
#import "FBPaymentObserver.h"
#import "FBRequest+Internal.h"
#import "FBSession+Internal.h"
#import "FBSessionAppEventsState.h"
#import "FBSessionManualTokenCachingStrategy.h"
#import "FBSettings+Internal.h"
#import "FBTimeSpentData.h"
#import "FBUtility.h"

//
// Public event names
//

// General purpose
NSString *const FBAppEventNameActivatedApp            = @"fb_mobile_activate_app";
NSString *const FBAppEventNameCompletedRegistration   = @"fb_mobile_complete_registration";
NSString *const FBAppEventNameViewedContent           = @"fb_mobile_content_view";
NSString *const FBAppEventNameSearched                = @"fb_mobile_search";
NSString *const FBAppEventNameRated                   = @"fb_mobile_rate";
NSString *const FBAppEventNameCompletedTutorial       = @"fb_mobile_tutorial_completion";
NSString *const FBAppEventParameterLaunchSource       = @"fb_mobile_launch_source";

// Ecommerce related
NSString *const FBAppEventNameAddedToCart             = @"fb_mobile_add_to_cart";
NSString *const FBAppEventNameAddedToWishlist         = @"fb_mobile_add_to_wishlist";
NSString *const FBAppEventNameInitiatedCheckout       = @"fb_mobile_initiated_checkout";
NSString *const FBAppEventNameAddedPaymentInfo        = @"fb_mobile_add_payment_info";
NSString *const FBAppEventNamePurchased               = @"fb_mobile_purchase";

// Gaming related
NSString *const FBAppEventNameAchievedLevel           = @"fb_mobile_level_achieved";
NSString *const FBAppEventNameUnlockedAchievement     = @"fb_mobile_achievement_unlocked";
NSString *const FBAppEventNameSpentCredits            = @"fb_mobile_spent_credits";

//
// Public event parameter names
//

NSString *const FBAppEventParameterNameCurrency               = @"fb_currency";
NSString *const FBAppEventParameterNameRegistrationMethod     = @"fb_registration_method";
NSString *const FBAppEventParameterNameContentType            = @"fb_content_type";
NSString *const FBAppEventParameterNameContentID              = @"fb_content_id";
NSString *const FBAppEventParameterNameSearchString           = @"fb_search_string";
NSString *const FBAppEventParameterNameSuccess                = @"fb_success";
NSString *const FBAppEventParameterNameMaxRatingValue         = @"fb_max_rating_value";
NSString *const FBAppEventParameterNamePaymentInfoAvailable   = @"fb_payment_info_available";
NSString *const FBAppEventParameterNameNumItems               = @"fb_num_items";
NSString *const FBAppEventParameterNameLevel                  = @"fb_level";
NSString *const FBAppEventParameterNameDescription            = @"fb_description";

//
// Public event parameter values
//

NSString *const FBAppEventParameterValueNo                    = @"0";
NSString *const FBAppEventParameterValueYes                   = @"1";

//
// Event names internal to this file
//

NSString *const FBAppEventNameLogConversionPixel               = @"fb_log_offsite_pixel";
NSString *const FBAppEventNameFriendPickerUsage                = @"fb_friend_picker_usage";
NSString *const FBAppEventNamePlacePickerUsage                 = @"fb_place_picker_usage";
NSString *const FBAppEventNameLoginViewUsage                   = @"fb_login_view_usage";
NSString *const FBAppEventNameUserSettingsUsage                = @"fb_user_settings_vc_usage";
NSString *const FBAppEventNameShareSheetLaunch                 = @"fb_share_sheet_launch";
NSString *const FBAppEventNameShareSheetDismiss                = @"fb_share_sheet_dismiss";
NSString *const FBAppEventNamePermissionsUILaunch              = @"fb_permissions_ui_launch";
NSString *const FBAppEventNamePermissionsUIDismiss             = @"fb_permissions_ui_dismiss";
NSString *const FBAppEventNameFBDialogsPresentShareDialog      = @"fb_dialogs_present_share";
NSString *const FBAppEventNameFBDialogsPresentShareDialogPhoto = @"fb_dialogs_present_share_photo";
NSString *const FBAppEventNameFBDialogsPresentShareDialogOG    = @"fb_dialogs_present_share_og";
NSString *const FBAppEventNameFBDialogsPresentLikeDialogOG     = @"fb_dialogs_present_like_og";
NSString *const FBAppEventNameFBDialogsPresentMessageDialog      = @"fb_dialogs_present_message";
NSString *const FBAppEventNameFBDialogsPresentMessageDialogPhoto = @"fb_dialogs_present_message_photo";
NSString *const FBAppEventNameFBDialogsPresentMessageDialogOG    = @"fb_dialogs_present_message_og";


NSString *const FBAppEventNameFBDialogsNativeLoginDialogStart  = @"fb_dialogs_native_login_dialog_start";
NSString *const FBAppEventsNativeLoginDialogStartTime          = @"fb_native_login_dialog_start_time";

NSString *const FBAppEventNameFBDialogsNativeLoginDialogEnd    = @"fb_dialogs_native_login_dialog_end";
NSString *const FBAppEventsNativeLoginDialogEndTime            = @"fb_native_login_dialog_end_time";

NSString *const FBAppEventNameFBDialogsWebLoginCompleted       = @"fb_dialogs_web_login_dialog_complete";
NSString *const FBAppEventsWebLoginE2E                         = @"fb_web_login_e2e";

NSString *const FBAppEventNameFBSessionAuthStart               = @"fb_mobile_login_start";
NSString *const FBAppEventNameFBSessionAuthEnd                 = @"fb_mobile_login_complete";
NSString *const FBAppEventNameFBSessionAuthMethodStart         = @"fb_mobile_login_method_start";
NSString *const FBAppEventNameFBSessionAuthMethodEnd           = @"fb_mobile_login_method_complete";

NSString *const FBAppEventNameFBLikeControlDidDisable          = @"fb_like_control_did_disable";
NSString *const FBAppEventNameFBLikeControlDidLike             = @"fb_like_control_did_like";
NSString *const FBAppEventNameFBLikeControlDidPresentDialog    = @"fb_like_control_did_present_dialog";
NSString *const FBAppEventNameFBLikeControlDidTap              = @"fb_like_control_did_tap";
NSString *const FBAppEventNameFBLikeControlDidUnlike           = @"fb_like_control_did_unlike";
NSString *const FBAppEventNameFBLikeControlError               = @"fb_like_control_error";
NSString *const FBAppEventNameFBLikeControlImpression          = @"fb_like_control_impression";
NSString *const FBAppEventNameFBLikeControlNetworkUnavailable  = @"fb_like_control_network_unavailable";

// Event Parameters internal to this file
NSString *const FBAppEventParameterConversionPixelID           = @"fb_offsite_pixel_id";
NSString *const FBAppEventParameterConversionPixelValue        = @"fb_offsite_pixel_value";
NSString *const FBAppEventParameterDialogOutcome               = @"fb_dialog_outcome";
NSString *const FBAppEventParameterImplicitlyLoggedPurchase    = @"_implicitlyLoggedPurchaseEvent";

// Event parameter values internal to this file
NSString *const FBAppEventsDialogOutcomeValue_Completed = @"Completed";
NSString *const FBAppEventsDialogOutcomeValue_Cancelled = @"Cancelled";
NSString *const FBAppEventsDialogOutcomeValue_Failed    = @"Failed";


NSString *const FBAppEventsLoggingResultNotification = @"com.facebook.sdk:FBAppEventsLoggingResultNotification";
NSString *const FBAppEventsActivateAppFlush = @"com.facebook.sdk:FBAppEventsActivateAppFlush%@";

// Keys to get App-specific info from mainBundle
NSString *const FBPLISTLoggingOverrideAppIDKey = @"FacebookLoggingOverrideAppID";

@interface FBAppEvents ()

#pragma mark - typedefs

typedef NS_ENUM(NSUInteger, AppSettingsFetchState) {
    AppSettingsFetchStateUnknown,
    AppSettingsFetchStateInProgress,
    AppSettingsFetchStateSucceeded,
};

typedef void (^FetchAppSettingsCallback)(void);

@property (readwrite) FBAppEventsFlushBehavior      flushBehavior;
@property (readwrite, copy) NSString               *loggingOverrideAppID;
@property (readwrite) BOOL                          haveOutstandingPersistedData;
@property (readwrite) BOOL                          explicitEventsLoggedYet;
@property (readwrite, retain) FBSession            *lastSessionLoggedTo;
@property (readwrite, retain) NSTimer              *flushTimer;
@property (readwrite, retain) NSTimer              *attributionIDRecheckTimer;
@property (readwrite) AppSettingsFetchState         appSettingsFetchState;
@property (readwrite) BOOL                          appSupportsImplicitLogging;
@property (readwrite) BOOL                          shouldAccessAdvertisingID;
@property (readwrite) BOOL                          doesAppLogImplicitPurchaseEvents;
@property (readwrite) BOOL                          haveFetchedAppSettings;
@property (readwrite, copy) NSRegularExpression    *eventNameRegex;
@property (readwrite, retain) NSMutableSet         *validatedIdentifiers;
@property (readonly, retain) NSMutableDictionary   *appAuthSessions;  // Dictionary from appIDs to ClientToken-based app-authenticated session for that appID.
@property (readonly, retain) NSMutableDictionary   *anonymousSessions;

@end

@implementation FBAppEvents

NSString *const FBAppEventsPersistedEventsFilename   = @"com-facebook-sdk-AppEventsPersistedEvents.json";

NSString *const FBAppEventsPersistKeyNumSkipped      = @"numSkipped";
NSString *const FBAppEventsPersistKeyEvents          = @"events";

#pragma static vars
static NSString *_sourceApplication;
static BOOL _isOpenedByAppLink;

#pragma mark - Constants

const int NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER       = 100;
const int FLUSH_PERIOD_IN_SECONDS                    = 15;
const int APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD = 60 * 60 * 24;
const int MAX_IDENTIFIER_LENGTH                      = 40;

#pragma mark - logEvent variants

/*
 * Event logging
 */
+ (void)logEvent:(NSString *)eventName {
    [FBAppEvents logEvent:eventName
              parameters:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum {
    [FBAppEvents logEvent:eventName
              valueToSum:valueToSum
              parameters:nil];
}

+ (void)logEvent:(NSString *)eventName
      parameters:(NSDictionary *)parameters {
    [FBAppEvents logEvent:eventName
              valueToSum:nil
              parameters:parameters
                 session:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
      parameters:(NSDictionary *)parameters {
    [FBAppEvents logEvent:eventName
              valueToSum:[NSNumber numberWithDouble:valueToSum]
              parameters:parameters
                 session:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(NSNumber *)valueToSum
      parameters:(NSDictionary *)parameters
         session:(FBSession *)session {
    [FBAppEvents.singleton instanceLogEvent:eventName
                                valueToSum:valueToSum
                                parameters:parameters
                        isImplicitlyLogged:NO
                                   session:session];
}


+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
                 session:(FBSession *)session {

    [FBAppEvents.singleton instanceLogEvent:eventName
                                valueToSum:valueToSum
                                parameters:parameters
                        isImplicitlyLogged:YES
                                   session:session];
}

#pragma mark - logPurchase variants

+ (void)logImplicitPurchaseEvent:(NSString *)eventName
                      valueToSum:(NSNumber *)valueToSum
                      parameters:(NSDictionary *)parameters
                         session:(FBSession *)session {
    NSMutableDictionary *eventParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [eventParameters setObject:@"1" forKey:FBAppEventParameterImplicitlyLoggedPurchase];
    [FBAppEvents.singleton instanceLogEvent:eventName
                                 valueToSum:valueToSum
                                 parameters:parameters
                         isImplicitlyLogged:YES
                                    session:session];

    // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since purchase events
    // are relatively rare and relatively high value and worth getting across on wire right away.
    if ([FBAppEvents flushBehavior] != FBAppEventsFlushBehaviorExplicitOnly) {
        [FBAppEvents.singleton instanceFlush:FBAppEventsFlushReasonEagerlyFlushingEvent];
    }
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency {
    [FBAppEvents logPurchase:purchaseAmount
                    currency:currency
                  parameters:nil];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters {
    [FBAppEvents logPurchase:purchaseAmount
                    currency:currency
                  parameters:parameters
                     session:nil];

}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters
            session:(FBSession *)session {

    // A purchase event is just a regular logged event with a given event name
    // and treating the currency value as going into the parameters dictionary.

    NSDictionary *newParameters;
    if (!parameters) {
        newParameters = @{ FBAppEventParameterNameCurrency : currency };
    } else {
        newParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [newParameters setValue:currency forKey:FBAppEventParameterNameCurrency];
    }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [FBAppEvents logEvent:FBAppEventNamePurchased
              valueToSum:[NSNumber numberWithDouble:purchaseAmount]
              parameters:newParameters
                 session:session];
#pragma GCC diagnostic pop

    // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since purchase events
    // are relatively rare and relatively high value and worth getting across on wire right away.
    if ([FBAppEvents flushBehavior] != FBAppEventsFlushBehaviorExplicitOnly) {
        [FBAppEvents.singleton instanceFlush:FBAppEventsFlushReasonEagerlyFlushingEvent];
    }

}

#pragma mark - Conversion Pixels

// Deprecated... only accessed through FBInsights
+ (void)logConversionPixel:(NSString *)pixelID
              valueOfPixel:(double)value
                   session:(FBSession *)session {

    // This method exists to allow a single API to be invoked to log a conversion pixel from a native mobile app
    // (and thus readily included in a snippet).  It logs the event with known event name and parameter names.
    // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since pixel firings
    // are relatively rare and relatively high value and worth getting across on wire right away.

    if (!pixelID) {
        [FBAppEvents logAndNotify:@"Conversion Pixel ID cannot be nil"];
        return;
    }

    [FBAppEvents logEvent:FBAppEventNameLogConversionPixel
              valueToSum:[NSNumber numberWithDouble:value]
              parameters:@{ FBAppEventParameterConversionPixelID : pixelID,
                            FBAppEventParameterConversionPixelValue : [NSNumber numberWithDouble:value] }
                 session:session];

    if ([FBAppEvents flushBehavior] != FBAppEventsFlushBehaviorExplicitOnly) {
        [FBAppEvents.singleton instanceFlush:FBAppEventsFlushReasonEagerlyFlushingEvent];
    }
}

#pragma mark - Event usage

// Deprecated... access through FBSettings.limitEventAndDataUsage
+ (BOOL)limitEventUsage {
    return FBSettings.limitEventAndDataUsage;
}

// Deprecated... access through FBSettings.limitEventAndDataUsage
+ (void)setLimitEventUsage:(BOOL)limitEventUsage {
    FBSettings.limitEventAndDataUsage = limitEventUsage;
}

+ (void)activateApp {
    [FBAppEvents ensureOnMainThread];

    // activateApp publishes an install on the first launch, and then logs an
    // activate app event.
    [FBSettings publishInstall:nil];

    // Fetch app settings and register for transaction notifications only if app supports implicit purchase
    // events
    FBAppEvents *instance = [FBAppEvents singleton];
    [instance fetchAppSettings:nil];

    // Restore time spent data, indicating that we're being called from "activateApp", which will,
    // when appropriate, result in logging an "activated app" and "deactivated app" (for the
    // previous session) App Event.
    [FBTimeSpentData restore:YES];
}

#pragma mark - Flushing & Session Management

+ (FBAppEventsFlushBehavior)flushBehavior {
    return FBAppEvents.singleton.flushBehavior;
}

+ (void)setFlushBehavior:(FBAppEventsFlushBehavior)flushBehavior {
    FBAppEvents.singleton.flushBehavior = flushBehavior;
}

+ (NSString *)loggingOverrideAppID {
    return FBAppEvents.singleton.loggingOverrideAppID;
}

+ (void)setLoggingOverrideAppID:(NSString *)appID {

    FBConditionalLog(!FBAppEvents.singleton.explicitEventsLoggedYet,
                     FBLoggingBehaviorDeveloperErrors,
                     @"[FBAppEvents setLoggingOverrideAppID:] should only be called prior to any events being logged.");

    FBAppEvents.singleton.loggingOverrideAppID = appID;
}

+ (void)flush {
    [FBAppEvents.singleton instanceFlush:FBAppEventsFlushReasonExplicit];
}

#pragma mark - Private Methods


+ (FBAppEvents *)singleton {
    static dispatch_once_t pred;
    static FBAppEvents *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[FBAppEvents alloc] init];
    });
    return shared;
}


/**
 *
 * Multithreading Principles
 *
 * Logging events may be invoked from any thread.  The FBSession-specific logging data structures
 * will be locked before being updated.  Flushes, be they invoked explicitly or implicitly, will be
 * dispatched to the main thread.
 *
 * FBSessionAppEventsState is a chunk of state that hangs off of FBSession and holds event state
 * destined for that session.
 *
 * That FBSessionAppEventsState instance itself is used as the synchronization object for most logging
 * state.  For multi-thread accessed global state, we synchronize mostly on the FBAppEvents singleton object.
 *
 * The other singleton state is intended to be accessed from the main thread only (though certain ones, like
 * flushBehavior, are innocuous enough that it doesn't matter).
 *
 * Every method here that is expected to be called from the main thread should have
 * [FBAppEvents ensureOnMainThread] at its top.  This just does an FBConditionalLog if it's not the main thread,
 * but indicates a clear logic error in how this is being used when that occurs.
 */


- (FBAppEvents *)init {
    self = [super init];
    if (self) {
        // Default haveOutstandingPersistedData to YES in case the app was killed before it could upload data
        // This will still require a session and a call to logEvent at some point to set that session up
        self.haveOutstandingPersistedData = YES;
        self.flushBehavior = FBAppEventsFlushBehaviorAuto;
        self.appSettingsFetchState = AppSettingsFetchStateUnknown;

        _appAuthSessions = [[NSMutableDictionary alloc] init];
        _anonymousSessions = [[NSMutableDictionary alloc] init];

        // Timer fires unconditionally on a regular interval... handler decides whether to call flush.
        self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:FLUSH_PERIOD_IN_SECONDS
                                                           target:self
                                                         selector:@selector(flushTimerFired:)
                                                         userInfo:nil
                                                          repeats:YES];

        self.attributionIDRecheckTimer = [NSTimer scheduledTimerWithTimeInterval:APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD
                                                                          target:self
                                                                        selector:@selector(appSettingsFetchStateResetTimerFired:)
                                                                        userInfo:nil
                                                                         repeats:YES];

        // Register an observer to watch for app moving out of the active state, which we use
        // to signal a flush.  Since this is static, we don't unregister anywhere.
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationMovingFromActiveStateOrTerminating)
         name:UIApplicationWillResignActiveNotification
         object:NULL];

        // Register for app termination, where we'll persist unsent events.
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationMovingFromActiveStateOrTerminating)
         name:UIApplicationWillTerminateNotification
         object:NULL];

        // And register for app activation, where we'll set up persisted events to be set.
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationDidBecomeActive)
         name:UIApplicationDidBecomeActiveNotification
         object:NULL];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_anonymousSessions release];
    [_appAuthSessions release];
    [_attributionIDRecheckTimer release];
    [_eventNameRegex release];
    [_flushTimer release];
    [_lastSessionLoggedTo release];
    [_loggingOverrideAppID release];
    [_validatedIdentifiers release];

    [super dealloc];
}

- (void)fetchAppSettings:(FetchAppSettingsCallback)fetchAppSettingsCallback {
    NSString *appid = [[[FBSettings defaultAppID] copy] autorelease];

    [FBAppEvents ensureOnMainThread];

    if (self.appSettingsFetchState == AppSettingsFetchStateInProgress) {
        return;
    } else if (self.appSettingsFetchState == AppSettingsFetchStateSucceeded) {
        if (fetchAppSettingsCallback) {
            fetchAppSettingsCallback();
        }
        return;
    }

    self.appSettingsFetchState = AppSettingsFetchStateInProgress;
    [FBUtility fetchAppSettings:appid
                       callback:^(FBFetchedAppSettings *settings, NSError *error) {

                           [FBAppEvents ensureOnMainThread];

                           self.appSupportsImplicitLogging = settings.supportsImplicitSdkLogging;
                           self.shouldAccessAdvertisingID = settings.shouldAccessAdvertisingID;
                           self.doesAppLogImplicitPurchaseEvents = settings.doesAppLogImplicitPurchaseEvents;
                           if (!error) {
                               self.appSettingsFetchState = AppSettingsFetchStateSucceeded;
                           } else {
                               self.appSettingsFetchState = AppSettingsFetchStateUnknown;
                           }
                           // Start or stop observing transactions depending on whether the app logs implicit purchase events
                           // This is a NOP if we're already observing transactions/not observing transactions
                           if (self.doesAppLogImplicitPurchaseEvents) {
                               [FBPaymentObserver startObservingTransactions];
                           } else {
                               [FBPaymentObserver stopObservingTransactions];
                           }
                           if (fetchAppSettingsCallback) {
                               fetchAppSettingsCallback();
                           }
                       }
     ];
}

- (BOOL)validateIdentifier:(NSString *)identifier {

    if (identifier == nil || identifier.length == 0 || identifier.length > MAX_IDENTIFIER_LENGTH || ![self regexValidateIdentifier:identifier]) {
        [FBAppEvents logAndNotify:[NSString stringWithFormat:@"Invalid identifier: '%@'.  Must be between 1 and %d characters, and must be contain only alphanumerics, _, - or spaces, starting with alphanumeric or _.",
                                  identifier, MAX_IDENTIFIER_LENGTH]];
        return NO;
    }

    return YES;
}

- (BOOL)regexValidateIdentifier:(NSString *)identifier {

    if (!self.eventNameRegex) {

        // Event name must only have 0-9A-Za-z, underscore, hyphen, and space (but no hyphen or space in the first position).
        NSString *regex = @"^[0-9a-zA-Z_]+[0-9a-zA-Z _-]*$";

        NSError *regexError;
        self.eventNameRegex = [NSRegularExpression regularExpressionWithPattern:regex
                                                                        options:0
                                                                          error:&regexError];
        self.validatedIdentifiers = [[[NSMutableSet alloc] init] autorelease];
    }

    if (![self.validatedIdentifiers containsObject:identifier]) {
        NSUInteger numMatches = [self.eventNameRegex numberOfMatchesInString:identifier options:0 range:NSMakeRange(0, identifier.length)];
        if (numMatches > 0) {
            [self.validatedIdentifiers addObject:identifier];
        } else {
            return NO;
        }
    }

    return YES;
}

- (void)instanceLogEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
                 session:(FBSession *)session {

    // Bail out of implicitly logged events if we know we're not doing implicit logging.
    if (isImplicitlyLogged && self.haveFetchedAppSettings && !self.appSupportsImplicitLogging) {
        return;
    }

    if (!isImplicitlyLogged && !self.explicitEventsLoggedYet) {
        self.explicitEventsLoggedYet = YES;
    }

    __block BOOL failed = NO;

    if (![self validateIdentifier:eventName]) {
        failed = YES;
    }

    // Make sure parameter dictionary is well formed.  Log and exit if not.
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

        if (![key isKindOfClass:[NSString class]]) {
            [FBAppEvents logAndNotify:[NSString stringWithFormat:@"The keys in the parameters must be NSStrings, '%@' is not.", key]];
            failed = YES;
        }

        if (![self validateIdentifier:key]) {
            failed = YES;
        }

        if (![obj isKindOfClass:[NSString class]] && ![obj isKindOfClass:[NSNumber class]]) {
            [FBAppEvents logAndNotify:[NSString stringWithFormat:@"The values in the parameters dictionary must be NSStrings or NSNumbers, '%@' is not.", obj]];
            failed = YES;
        }

    }
     ];

    if (failed) {
        return;
    }

    // Push the event onto the queue for later flushing.

    FBSession *sessionToLogTo = [self sessionToSendRequestTo:session];
    NSMutableDictionary *eventDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];

    long logTime = [FBAppEvents unixTimeNow];
    [eventDictionary setObject:eventName forKey:@"_eventName"];
    [eventDictionary setObject:[NSNumber numberWithLong:logTime] forKey:@"_logTime"];

    if (valueToSum != nil) {
        [eventDictionary setObject:valueToSum forKey:@"_valueToSum"];
    }

    if (isImplicitlyLogged) {
        [eventDictionary setObject:@"1" forKey:@"_implicitlyLogged"];
    }

    NSString *currentViewControllerName;
    if ([NSThread isMainThread]) {
        // We only collect the view controller when on the main thread, as the behavior off
        // the main thread is unpredictable.  Besides, UI state for off-main-thread computations
        // isn't really relevant anyhow.
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
        if (vc) {
            currentViewControllerName = [[vc class] description];
        } else {
            currentViewControllerName = @"no_ui";
        }
    } else {
        currentViewControllerName = @"off_thread";
    }
    [eventDictionary setObject:currentViewControllerName forKey:@"_ui"];

    @synchronized (self) {
        // If this is a different session than the most recent we logged to, set up that earlier session for flushing, and update
        // the most recent.
        if (!self.lastSessionLoggedTo) {
            self.lastSessionLoggedTo = sessionToLogTo;
        }

        if (self.lastSessionLoggedTo != sessionToLogTo) {
            // Since we're not logging to lastSessionLoggedTo, at least for now, set it up for flushing.  If we swap back and
            // forth frequently between sessions, this could be thrashy, but that's not an expected use case of the SDK.
            [self flush:FBAppEventsFlushReasonSessionChange session:self.lastSessionLoggedTo];
            self.lastSessionLoggedTo = sessionToLogTo;
        }

        FBSessionAppEventsState *appEventsState = sessionToLogTo.appEventsState;

        [appEventsState addEvent:eventDictionary isImplicit:isImplicitlyLogged];

        if (!isImplicitlyLogged) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                            formatString:@"FBAppEvents: Recording event @ %ld: %@",
                [FBAppEvents unixTimeNow],
                eventDictionary];
        }

        BOOL eventsRetrievedFromPersistedData = NO;
        if (self.haveOutstandingPersistedData) {
            // Now that we have a session, we can read in our persisted data.
            eventsRetrievedFromPersistedData = [self updateAppEventsStateWithPersistedData:sessionToLogTo];
            self.haveOutstandingPersistedData = NO;
        }

        if (self.flushBehavior != FBAppEventsFlushBehaviorExplicitOnly) {

            if (appEventsState.getAccumulatedEventCount > NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER) {
                [self flush:FBAppEventsFlushReasonEventThreshold session:sessionToLogTo];
            } else if (eventsRetrievedFromPersistedData) {
                [self flush:FBAppEventsFlushReasonPersistedEvents session:sessionToLogTo];
            }

        }
    }
}

- (void)instanceFlush:(FBAppEventsFlushReason)flushReason {
    if (self.lastSessionLoggedTo) {  // nil only if no logging yet, instanceLogEvent will fill this in.
        [self flush:flushReason session:self.lastSessionLoggedTo];
    }
}


- (void)flush:(FBAppEventsFlushReason)flushReason
      session:(FBSession *)session {

    // Always flush asynchronously, even on main thread, for two reasons:
    // - most consistent code path for all threads.
    // - allow locks being held by caller to be released prior to actual flushing work being done.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self flushOnMainQueue:flushReason session:session];
    });
}

/*

 Event sending procedure:

 - always executing on the main thread, and the flush is targeted at the appEventsState on the session
 - if request is currently in-flight, return
 - extend the 'inFlight' event list with the list of current events
 - clear out the current event list (since logEvents during this request will add to it)
 - send request
 - if request result is:
   + success: clear out the inFlight event list, invoke the delegate with success
   + server error: clear out the inFlight event list, log, and publish to NotificationCenter with error
   + cannot connect: keep inFlight event list intact

 After N minutes, the process will be re-invoked if there are items in the inFlight list, or
 you haven't chosen ExplicitOnly flush.

 On app deactivation/backgrounding: persist the inFlight events.  No time to try to send.
 On app termination: Persist the inFlight events
 On app activation: Read back from persisted data and flush asap.

 */
- (void)flushOnMainQueue:(FBAppEventsFlushReason)flushReason
                 session:(FBSession *)session {
    [FBAppEvents ensureOnMainThread];
    FBSessionAppEventsState *appEventsState = session.appEventsState;

    // If trying to flush a session already in flight, just ignore and continue to accum events
    // until we try to flush again.
    if (appEventsState.requestInFlight) {
        return;
    }

   // Execute the actual flush after we fetch app settings. fetchAppSettings determines if an actual
    // fetch is needed or not.
    [self fetchAppSettings:^(void) {
            // Kick off the original flush, now that we have the info we need.
            [self flushEventsToServer:flushReason session:session];
        }
    ];

}

- (void)flushEventsToServer:(FBAppEventsFlushReason)flushReason
                    session:(FBSession *)session {
    [FBAppEvents ensureOnMainThread];
    FBSessionAppEventsState *appEventsState = session.appEventsState;

    NSString *appid = [self appIDToLogEventsWith:session];

    NSString *jsonEncodedEvents;
    NSUInteger eventCount, numSkipped;
    BOOL allEventsAreImplicit;
    @synchronized (appEventsState) {

        [appEventsState.inFlightEvents addObjectsFromArray:appEventsState.accumulatedEvents];
        [appEventsState.accumulatedEvents removeAllObjects];
        eventCount = appEventsState.inFlightEvents.count;

        if (!eventCount) {
            return;
        }

        allEventsAreImplicit = [appEventsState areAllEventsImplicit];
        jsonEncodedEvents = [appEventsState jsonEncodeInFlightEvents:self.appSupportsImplicitLogging];
        numSkipped = appEventsState.numSkippedEventsDueToFullBuffer;
    }

    // Move custom events field off the URL and into a POST field only by encoding into UTF8, which the server
    // will then handle as an uploaded file.  It also allows request compression to work on event data.
    NSData *utf8EncodedEvents = [jsonEncodedEvents dataUsingEncoding:NSUTF8StringEncoding];

    if (!utf8EncodedEvents) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                            logEntry:@"FBAppEvents: Flushing skipped - no events after removing implicitly logged ones.\n"];
        return;
    }

    NSMutableDictionary<FBGraphObject> *postParameters =
        [FBUtility activityParametersDictionaryForEvent:@"CUSTOM_APP_EVENTS"
                                     implicitEventsOnly:allEventsAreImplicit
                              shouldAccessAdvertisingID:self.shouldAccessAdvertisingID];
    postParameters[@"custom_events_file"] = utf8EncodedEvents;
    if (numSkipped > 0) {
        postParameters[@"num_skipped_events"] = [NSString stringWithFormat:@"%lu", (unsigned long)numSkipped];
    }

    NSString *loggingEntry = nil;
    if ([[FBSettings loggingBehavior] containsObject:FBLoggingBehaviorAppEvents]) {

        id decodedEvents = [FBUtility simpleJSONDecode:jsonEncodedEvents];
        NSString *prettyPrintedJsonEvents = [FBUtility simpleJSONEncode:decodedEvents
                                                                  error:nil
                                                         writingOptions:NSJSONWritingPrettyPrinted];

        // Remove this param -- just an encoding of the events which we pretty print later.
        NSMutableDictionary *paramsForPrinting = [NSMutableDictionary dictionaryWithDictionary:postParameters];
        [paramsForPrinting removeObjectForKey:@"custom_events_file"];

        loggingEntry = [NSString stringWithFormat:@"FBAppEvents: Flushed @ %ld, %lu events due to '%@' - %@\nEvents: %@",
                        [FBAppEvents unixTimeNow],
                        (unsigned long)eventCount,
                        [FBAppEvents flushReasonToString:flushReason],
                        paramsForPrinting,
                        prettyPrintedJsonEvents];
    }

    FBRequest *request = [[[FBRequest alloc] initWithSession:session
                                                   graphPath:[NSString stringWithFormat:@"%@/activities", appid]
                                                  parameters:postParameters
                                                  HTTPMethod:@"POST"] autorelease];
    request.canCloseSessionOnError = NO;

    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self handleActivitiesPostCompletion:error
                                loggingEntry:loggingEntry
                                     session:session];
    }];

    appEventsState.requestInFlight = YES;
}

- (BOOL)doesSessionHaveUserToken:(FBSession *)session {
    // Assume that if we're not using an appAuthSession (built from the Client Token) or the anonymous session,
    // then we have a logged in user token.
    FBSession *appAuthSession = [self.appAuthSessions objectForKey:session.appID];
    if (session == appAuthSession) {
        return NO;
    }
    NSSet *matchingAnonymousSessions = [self.anonymousSessions keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return (obj == session);
    }];
    return matchingAnonymousSessions.count == 0;
}

- (NSString *)appIDToLogEventsWith:(FBSession *)candidateSession {

    NSString *result = self.loggingOverrideAppID;
    if (!result) {
        result = [[[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTLoggingOverrideAppIDKey] copy] autorelease];
    }

    if (!result) {
        result = candidateSession.appID;
    }

    return result;
}


// Given a candidate session (which may be nil), find the real session to send the FBRequest to (with an access token).
// Precedence: 1) provided session, 2) activeSession, 3) app authenticated session, 4) fully anonymous session.
// When clientToken-annotated calls move outside of the domain of stuff handled in this file, we may want to move this as a
// helper into FBSession.  When a loggingOverride appID is present, we can never use this session.
- (FBSession *)sessionToSendRequestTo:(FBSession *)session {

    if (!session) {
        // Note: activeSession's appID will be [FBSettings defaultAppID] unless otherwise established.
        session = [FBSession activeSession];
    }

    NSString *appID = [self appIDToLogEventsWith:session];

    if (!session.accessTokenData.accessToken || ![appID isEqualToString:session.appID]) {

        NSString *clientToken = [FBSettings clientToken];

        // If there's an logging override app id present, then we don't want to use the client token since the client token
        // is intended to match up with the primary app id (and AppEvents doesn't require a client token).
        if (clientToken && appID && [appID isEqualToString:session.appID]) {

            FBSession *appAuthSession = [self.appAuthSessions objectForKey:appID];
            if (!appAuthSession) {

                @synchronized(self) {

                    appAuthSession = [self.appAuthSessions objectForKey:appID];  // in case it snuck in
                    if (!appAuthSession) {

                        FBSessionManualTokenCachingStrategy *tokenCaching = [[FBSessionManualTokenCachingStrategy alloc] init];
                        tokenCaching.accessToken = [NSString stringWithFormat:@"%@|%@", appID, clientToken];
                        tokenCaching.expirationDate = [NSDate dateWithTimeIntervalSinceNow:315360000]; // 10 years from now

                        // Create session with explicit token and stash with appID.
                        appAuthSession = [FBAppEvents unaffinitizedSessionFromToken:tokenCaching
                                                                              appID:appID];
                        [tokenCaching release];

                        [self.appAuthSessions setObject:appAuthSession forKey:appID];
                    }
                }
            }
            session = appAuthSession;

        } else if (appID) {
            // Note appID cannot be nil at this point but we have a conditional to satisfy clang.
            FBSession *anonymousSession = self.anonymousSessions[appID];
            // No clientToken, create session without access token that can be used for logging the events in 'eventsNotRequiringToken', preferring
            // appID coming in with the incoming session (or the activeSession), even if they don't have an access token.
            if (!anonymousSession) {

                @synchronized(self) {

                    if (!anonymousSession) {  // in case it snuck in
                        anonymousSession = [FBAppEvents unaffinitizedSessionFromToken:[FBSessionTokenCachingStrategy nullCacheInstance]
                                                                                     appID:appID];
                        self.anonymousSessions[appID] = anonymousSession;
                    }
                }
            }
            session = anonymousSession;
        }

    }

    return session;
}

+ (FBSession *)unaffinitizedSessionFromToken:(FBSessionTokenCachingStrategy *)tokenCachingStrategy
                                       appID:(NSString *)appID {

    // Passing in nil for appID will result in using [FBSettings defaultAppID], and the right exception
    // behavior will happen if that is null.
    FBSession *session = [[[FBSession alloc] initWithAppID:appID
                                               permissions:nil
                                           urlSchemeSuffix:nil
                                        tokenCacheStrategy:tokenCachingStrategy]
                          autorelease];

    // This may have been created off of the main thread, so clear out the affinitizedThread, and it will be
    // reset to the main thread on the first "real" operation on it.
    [session clearAffinitizedThread];

    return session;
}

+ (long)unixTimeNow {
    return (long)round([[NSDate date] timeIntervalSince1970]);
}


- (void)handleActivitiesPostCompletion:(NSError *)error
                          loggingEntry:(NSString *)loggingEntry
                               session:(FBSession *)session {

    typedef NS_ENUM(NSUInteger, FlushResult) {
        FlushResultSuccess,
        FlushResultServerError,
        FlushResultNoConnectivity
    };

    [FBAppEvents ensureOnMainThread];

    FlushResult flushResult = FlushResultSuccess;
    if (error) {

        NSInteger errorCode = [[[error userInfo] objectForKey:FBErrorHTTPStatusCodeKey] integerValue];

        // We interpret a 400 coming back from FBRequestConnection as a server error due to improper data being
        // sent down.  Otherwise we assume no connectivity, or another condition where we could treat it as no connectivity.
        flushResult = errorCode == 400 ? FlushResultServerError : FlushResultNoConnectivity;
    }

    FBSessionAppEventsState *appEventsState = session.appEventsState;
    BOOL allEventsAreImplicit = YES;
    @synchronized (appEventsState) {
        if (flushResult != FlushResultNoConnectivity) {
            for (NSDictionary *eventAndImplicitFlag in appEventsState.inFlightEvents) {
                if (![eventAndImplicitFlag[kFBAppEventIsImplicit] boolValue]) {
                    allEventsAreImplicit = NO;
                    break;
                }
            }

            // Either success or a real server error.  Either way, no more in flight events.
            [appEventsState clearInFlightAndStats];
        }

        appEventsState.requestInFlight = NO;
    }

    if (flushResult == FlushResultServerError) {
        [FBAppEvents logAndNotify:[error description] allowLogAsDeveloperError:!allEventsAreImplicit];
    }

    NSString *resultString = @"<unknown>";
    switch (flushResult) {
        case FlushResultSuccess:
            resultString = @"Success";
            break;

        case FlushResultNoConnectivity:
            resultString = @"No Connectivity";
            break;

        case FlushResultServerError:
            resultString = [NSString stringWithFormat:@"Server Error - %@", [error description]];
            break;
    }

    [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                    formatString:@"%@\nFlush Result : %@", loggingEntry, resultString];
}


- (void)flushTimerFired:(id)arg {
    [FBAppEvents ensureOnMainThread];

    @synchronized (self) {
        if (self.flushBehavior != FBAppEventsFlushBehaviorExplicitOnly) {
            if (self.lastSessionLoggedTo.appEventsState.inFlightEvents.count > 0 ||
                self.lastSessionLoggedTo.appEventsState.accumulatedEvents.count > 0) {

                [self flush:FBAppEventsFlushReasonTimer session:self.lastSessionLoggedTo];
            }
        }
    }
}

- (void)appSettingsFetchStateResetTimerFired:(id)arg {
    [FBAppEvents ensureOnMainThread];

    if (self.appSettingsFetchState != AppSettingsFetchStateInProgress) {
        // Reset app settings fetch state so it will be re-fetched in the event there was a server change.
        self.appSettingsFetchState = AppSettingsFetchStateUnknown;
    }
}

- (void)applicationDidBecomeActive {

    [FBAppEvents ensureOnMainThread];

    // We associate the deserialized persisted data with the current session.
    // It's possible we'll get false attribution if the user identity has changed
    // between the time the data was persisted and now, but we'll accept these
    // anomolies in the aggregate data (which should be rare anyhow).

    // Can only actively update state and log when we have a session, otherwise we
    // set a BOOL to tell us to update as soon as we can afterwards.
    if (self.lastSessionLoggedTo) {

        BOOL eventsRetrieved = [self updateAppEventsStateWithPersistedData:self.lastSessionLoggedTo];

        if (eventsRetrieved && self.flushBehavior != FBAppEventsFlushBehaviorExplicitOnly) {
            [self flush:FBAppEventsFlushReasonPersistedEvents session:self.lastSessionLoggedTo];
        }

    } else {

        self.haveOutstandingPersistedData = YES;

    }

    // Restore time spent data, indicating that we're not being called from "activateApp".
    [FBTimeSpentData restore:NO];
}

// Read back previously persisted events, if any, into specified session, returning whether any events were retrieved.
- (BOOL)updateAppEventsStateWithPersistedData:(FBSession *)session {

    BOOL eventsRetrieved = NO;
    NSDictionary *persistedData = [FBAppEvents retrievePersistedAppEventData];
    if (persistedData) {

        [FBAppEvents clearPersistedAppEventData];

        FBSessionAppEventsState *appEventsState = session.appEventsState;
        @synchronized (appEventsState) {
            appEventsState.numSkippedEventsDueToFullBuffer += [[persistedData objectForKey:FBAppEventsPersistKeyNumSkipped] unsignedIntegerValue];
            NSArray *retrievedObjects = [persistedData objectForKey:FBAppEventsPersistKeyEvents];
            if (retrievedObjects.count) {
                [appEventsState.inFlightEvents addObjectsFromArray:retrievedObjects];
                eventsRetrieved = YES;
            }
        }
    }

    return eventsRetrieved;
}

- (void)applicationMovingFromActiveStateOrTerminating {
    // When moving from active state, we don't have time to wait for the result of a flush, so
    // just persist events to storage, and we'll process them at the next activation.
    [self persistEventDataIfNotInFlight];

    [FBTimeSpentData suspend];
}

- (void)persistEventDataIfNotInFlight {
    [FBAppEvents ensureOnMainThread];

    FBSessionAppEventsState *appEventsState = self.lastSessionLoggedTo.appEventsState;
    if (appEventsState.requestInFlight) {
        // In flight request may or may not succeed, so there's no right thing to do here.  Err by just not doing anything on termination;
        return;
    }

    // Persist right away if needed (rather than trying one last sync) since we're about to be booted out.
    [FBAppEvents persistAppEventsData:appEventsState];
}

+ (void)logAndNotify:(NSString *)msg allowLogAsDeveloperError:(BOOL)allowLogAsDeveloperError {

    // capture reason and nested code as user info
    NSDictionary *userinfo = [NSDictionary dictionaryWithObject:msg forKey:FBErrorAppEventsReasonKey];

    // create error object
    NSError *err = [NSError errorWithDomain:FacebookSDKDomain
                                       code:FBErrorAppEvents
                                   userInfo:userinfo];

    NSString *behaviorToLog = FBLoggingBehaviorAppEvents;
    if (allowLogAsDeveloperError) {
        if ([[FBSettings loggingBehavior] containsObject:FBLoggingBehaviorDeveloperErrors]) {
            // Rather than log twice, prefer 'DeveloperErrors' if it's set over AppEvents.
            behaviorToLog = FBLoggingBehaviorDeveloperErrors;
        }
    }

    [FBLogger singleShotLogEntry:behaviorToLog logEntry:msg];

    [[NSNotificationCenter defaultCenter] postNotificationName:FBAppEventsLoggingResultNotification
                                                        object:err];
}

+ (void)logAndNotify:(NSString *)msg {
    [FBAppEvents logAndNotify:msg allowLogAsDeveloperError:YES];
}

#pragma mark - event log persistence

+ (void)persistAppEventsData:(FBSessionAppEventsState *)appEventsState {

    [FBAppEvents ensureOnMainThread];
    NSString *content;

    // We just persist from the last session being logged to.  When we switch sessions, we flush out
    // the one being moved away from.  So, modulo in-flight sessions, the only one with real data will
    // be the last one.

    @synchronized (appEventsState) {
        [appEventsState.inFlightEvents addObjectsFromArray:appEventsState.accumulatedEvents];
        [appEventsState.accumulatedEvents removeAllObjects];

        [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                        formatString:@"FBAppEvents Persist: Writing %lu events", (unsigned long)appEventsState.inFlightEvents.count];

        if (!appEventsState.inFlightEvents.count) {
            return;
        }

        NSDictionary *appEventData = @{
            FBAppEventsPersistKeyNumSkipped   : [NSNumber numberWithUnsignedInteger:appEventsState.numSkippedEventsDueToFullBuffer],
            FBAppEventsPersistKeyEvents       : appEventsState.inFlightEvents,
        };

        content = [FBUtility simpleJSONEncode:appEventData];

        [appEventsState clearInFlightAndStats];
    }

    //save content to the documents directory
    [content writeToFile:[FBAppEvents persistenceDocumentFilePath:FBAppEventsPersistedEventsFilename]
              atomically:YES
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];

}

+ (NSDictionary *)retrievePersistedAppEventData {

    NSString *content =
      [[NSString alloc] initWithContentsOfFile:[FBAppEvents persistenceDocumentFilePath:FBAppEventsPersistedEventsFilename]
                                  usedEncoding:nil
                                         error:nil];
    NSDictionary *results = [FBUtility simpleJSONDecode:content];
    [content release];

    [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                    formatString:@"FBAppEvents Persist: Read %lu events",
                    (unsigned long)(results ? [[results objectForKey:FBAppEventsPersistKeyEvents] count] : 0)];
    return results;
}

+ (void)clearPersistedAppEventData {

    [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                        logEntry:@"FBAppEvents Persist: Clearing"];
    [[NSFileManager defaultManager] removeItemAtPath:[FBAppEvents persistenceDocumentFilePath:FBAppEventsPersistedEventsFilename]
                                               error:nil];
}

+ (NSString *)persistenceDocumentFilePath:(NSString *)filename {
    return [FBAppEvents persistenceFilePath:filename directory:NSDocumentDirectory];
}

+ (NSString *)persistenceLibraryFilePath:(NSString *)filename {
    return [FBAppEvents persistenceFilePath:filename directory:NSLibraryDirectory];
}

+ (NSString *)persistenceFilePath:(NSString *)filename
                        directory:(NSSearchPathDirectory)directory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    return [docDirectory stringByAppendingPathComponent:filename];
}

+ (void)ensureOnMainThread {
    FBConditionalLog([NSThread isMainThread], FBLoggingBehaviorInformational, @"*** This method expected to be called on the main thread.");
}

#pragma mark - Custom Audience token stuff

// This code lives here in FBAppEvents because it shares many of the runtime characteristics of the FBAppEvents logging,
// even though the public exposure is elsewhere

+ (FBRequest *)customAudienceThirdPartyIDRequest:(FBSession *)session {
    return [FBAppEvents.singleton instanceCustomAudienceThirdPartyIDRequest:session];
}


- (FBRequest *)instanceCustomAudienceThirdPartyIDRequest:(FBSession *)session {

    // Rules for how we use the attribution ID / advertiser ID for an 'custom_audience_third_party_id' Graph API request
    // 1) if the OS tells us that the user has Limited Ad Tracking, then just don't send, and return a nil in the token.
    // 2) if the app has set 'limitEventAndDataUsage', this effectively implies that app-initiated ad targeting shouldn't happen,
    //    so use that data here to return nil as well.
    // 3) if we have a user session token, then no need to send attribution ID / advertiser ID back as the udid parameter
    // 4) otherwise, send back the udid parameter.

    if ([FBUtility advertisingTrackingStatus] == AdvertisingTrackingDisallowed || [FBSettings limitEventAndDataUsage]
        || [FBSettings restrictedTreatment] == FBRestrictedTreatmentYES) {
        return nil;
    }

    FBSession *sessionToSendRequestTo = [self sessionToSendRequestTo:session];
    NSString *udid = nil;
    if (![self doesSessionHaveUserToken:sessionToSendRequestTo]) {

        // We don't have a logged in user, so we need some form of udid representation.  Prefer advertiser ID if
        // available, and back off to attribution ID if not.  Note that this function only makes sense to be
        // called in the context of advertising.
        udid = [FBUtility advertiserID];
        if (!udid) {
            udid = [FBUtility attributionID];
        }

        if (!udid) {
            // No udid, and no user token.  No point in making the request.
            return nil;
        }
    }

    NSDictionary *parameters = nil;
    if (udid) {
        parameters = @{ @"udid" : udid };
    }

    NSString *graphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", sessionToSendRequestTo.appID];
    FBRequest *request = [[[FBRequest alloc] initWithSession:sessionToSendRequestTo
                                                   graphPath:graphPath
                                                  parameters:parameters
                                                  HTTPMethod:nil]
                          autorelease];
    request.canCloseSessionOnError = NO;

    return request;
}

+ (NSString *)flushReasonToString:(FBAppEventsFlushReason)flushReason {

    NSString *result = @"Unknown";
    switch (flushReason) {
        case FBAppEventsFlushReasonExplicit:
            result = @"Explicit";
            break;

        case FBAppEventsFlushReasonTimer:
            result = @"Timer";
            break;

        case FBAppEventsFlushReasonSessionChange:
            result = @"SessionChange";
            break;

        case FBAppEventsFlushReasonPersistedEvents:
            result = @"PersistedEvents";
            break;

        case FBAppEventsFlushReasonEventThreshold:
            result = @"EventCountThreshold";
            break;

        case FBAppEventsFlushReasonEagerlyFlushingEvent:
            result = @"EagerlyFlushingEvent";
            break;
    }

    return result;
}

+ (void)setSourceApplication:(NSString *)sourceApplication isAppLink:(BOOL)isAppLink {
    _sourceApplication = sourceApplication.copy;
    _isOpenedByAppLink = isAppLink;
}

+ (void)setSourceApplication:(NSString *)sourceApplication openURL:(NSURL *)url {
    [self setSourceApplication:sourceApplication
                     isAppLink:[FBUtility queryParamsDictionaryFromFBURL:url][@"al_applink_data"] != nil];
}

+ (NSString *)getSourceApplication {
    NSString *openType = @"Unclassified";
    if (_isOpenedByAppLink) {
        openType = @"AppLink";
    }
    if (_sourceApplication) {
        return [NSString stringWithFormat:@"%@(%@)", openType, _sourceApplication];
    } else {
        return openType;
    }
}

+ (void)registerAutoResetSourceApplication {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      _sourceApplication = nil;
                                                      _isOpenedByAppLink = NO;
                                                  }];
}

@end
