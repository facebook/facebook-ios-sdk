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

#import <UIKit/UIApplication.h>
#import "FBInsights.h"
#import "FBInsights+Internal.h"
#import "FBError.h"
#import "FBLogger.h"
#import "FBRequest.h"
#import "FBSession+Internal.h"
#import "FBSessionInsightsState.h"
#import "FBSessionManualTokenCachingStrategy.h"
#import "FBSettings.h"
#import "FBUtility.h"

//// Known (externally or internally) event names.
NSString *const FBInsightsEventNamePurchase                  = @"fb_mobile_purchase";
NSString *const FBInsightsEventNameAppLaunch                 = @"fb_app_launch";
NSString *const FBInsightsEventNameTimeSpentInApp            = @"fb_time_spent_in_app";
NSString *const FBInsightsEventNameLogConversionPixel        = @"fb_log_offsite_pixel";
NSString *const FBInsightsEventNameFriendPickerUsage         = @"fb_friend_picker_usage";
NSString *const FBInsightsEventNamePlacePickerUsage          = @"fb_place_picker_usage";

// These events may be logged when there's no clientToken-based or user-session based
// access token since they represent events that may occur implicitly when there's no one
// logged in.  Be sure to update the eventsNotRequiringToken set below if this list is changed.
NSString *const FBInsightsEventNameShareSheetLaunch          = @"fb_share_sheet_launch";
NSString *const FBInsightsEventNameShareSheetDismiss         = @"fb_share_sheet_dismiss";
NSString *const FBInsightsEventNamePermissionsUILaunch       = @"fb_permissions_ui_launch";
NSString *const FBInsightsEventNamePermissionsUIDismiss      = @"fb_permissions_ui_dismiss";
NSString *const FBInsightsEventNameFBDialogsCanPresentShareDialog   = @"fb_dialogs_can_present_share";
NSString *const FBInsightsEventNameFBDialogsCanPresentShareDialogOG = @"fb_dialogs_can_present_share_og";

NSString *const FBInsightsEventNameFBDialogsNativeLoginDialogStart = @"fb_dialogs_native_login_dialog_start";
NSString *const FBInsightsNativeLoginDialogStartTime = @"fb_native_login_dialog_start_time";

NSString *const FBInsightsEventNameFBDialogsWebLoginCompleted = @"fb_dialogs_web_login_dialog_complete";
NSString *const FBInsightsWebLoginE2E = @"fb_web_login_e2e";
NSString *const FBInsightsWebLoginSwitchbackTime = @"fb_web_login_switchback_time";

//// Known (externally or internally) event parameters.
NSString *const FBInsightsEventParameterCurrency             = @"fb_currency";
NSString *const FBInsightsEventParameterConversionPixelID    = @"fb_offsite_pixel_id";
NSString *const FBInsightsEventParameterConversionPixelValue = @"fb_offsite_pixel_value";
NSString *const FBInsightsEventParameterDialogOutcome        = @"fb_dialog_outcome";

//// Known (externally or internally) event parameter values
NSString *const FBInsightsDialogOutcomeValue_Completed       = @"Completed";
NSString *const FBInsightsDialogOutcomeValue_Cancelled       = @"Cancelled";
NSString *const FBInsightsDialogOutcomeValue_Failed          = @"Failed";

NSString *const FBInsightsLoggingResultNotification = @"com.facebook.sdk:FBInsightsLoggingResultNotification";

@interface FBInsights ()

#pragma mark - typedefs

typedef enum {
    AppSupportsAttributionUnknown,
    AppSupportsAttributionQueryInFlight,
    AppSupportsAttributionTrue,
    AppSupportsAttributionFalse,
} AppSupportsAttributionStatus;

typedef enum {
    FlushReasonExplicit,
    FlushReasonTimer,
    FlushReasonSessionChange,
    FlushReasonPersistedEvents,
    FlushReasonEventThreshold,
    FlushReasonEagerlyFlushingEvent
} FlushReason;

@property (readwrite, atomic, copy)   NSString                    *appVersion;
@property (readwrite, atomic)         FBInsightsFlushBehavior      flushBehavior;
@property (readwrite, atomic)         BOOL                         haveOutstandingPersistedData;
@property (readwrite, atomic, retain) FBSession                   *lastSessionLoggedTo;
@property (readwrite, atomic, retain) FBSession                   *anonymousSession;
@property (readwrite, atomic, retain) NSTimer                     *flushTimer;
@property (readwrite, atomic, retain) NSTimer                     *attributionIDRecheckTimer;
@property (readwrite, atomic, retain) NSSet                       *eventsNotRequiringToken;
@property (readwrite, atomic)         AppSupportsAttributionStatus appSupportsAttributionStatus;
@property (readwrite, atomic)         BOOL                         appSupportsImplicitLogging;
@property (readwrite, atomic)         BOOL                         haveFetchedAppSettings;

// Dictionary of dictionaries, each representing an incomplete, timed log event.
// The key is the timed log event name.
@property (readwrite, atomic, retain) NSMutableDictionary         *incompleteTimedEvents;

// Dictionary from appIDs to ClientToken-based app-authenticated session for that appID.
@property (readwrite, atomic, retain) NSMutableDictionary         *appAuthSessions;


@end

@implementation FBInsights

NSString *const FBInsightsPersistedEventsFilename   = @"com-facebook-sdk-InsightsPersistedEvents.json";

NSString *const FBInsightsPersistKeyNumAbandoned    = @"numAbandoned";
NSString *const FBInsightsPersistKeyNumSkipped      = @"numSkipped";
NSString *const FBInsightsPersistKeyEvents          = @"events";


#pragma mark - Constants

const int NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER       = 500;
const int FLUSH_PERIOD_IN_SECONDS                    = 60 * 5;
const int APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD = 60 * 60 * 24;


@synthesize
    appVersion = _appVersion,
    flushBehavior = _flushBehavior,
    haveOutstandingPersistedData = _haveOutstandingPersistedData,
    lastSessionLoggedTo = _lastSessionLoggedTo,
    anonymousSession = _anonymousSession,
    appAuthSessions = _appAuthSessions,
    flushTimer = _flushTimer,
    attributionIDRecheckTimer = _attributionIDRecheckTimer,
    eventsNotRequiringToken = _eventsNotRequiringToken,
    appSupportsAttributionStatus = _appSupportsAttributionStatus,
    appSupportsImplicitLogging = _appSupportsImplicitLogging,
    haveFetchedAppSettings = _haveFetchedAppSettings,
    incompleteTimedEvents = _incompleteTimedEvents;


/*
 * Global, session wide properties
 */

+ (NSString *)appVersion {
    return FBInsights.singleton.appVersion;
}

+ (void)setAppVersion:(NSString *)appVersion {
    FBInsights.singleton.appVersion = appVersion;
}

#pragma mark - logEvent variants

/*
 * Event logging
 */
+ (void)logEvent:(NSString *)eventName {
    [FBInsights logEvent:eventName
              valueToSum:1.0];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum {
    [FBInsights logEvent:eventName
              valueToSum:valueToSum
              parameters:nil];
}

+ (void)logEvent:(NSString *)eventName
      parameters:(NSDictionary *)parameters {
    [FBInsights logEvent:eventName
              valueToSum:1.0
              parameters:parameters];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
      parameters:(NSDictionary *)parameters {
    [FBInsights logEvent:eventName
              valueToSum:valueToSum
              parameters:parameters
                 session:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
      parameters:(NSDictionary *)parameters
         session:(FBSession *)session {
    [FBInsights.singleton instanceLogEvent:eventName
                                valueToSum:valueToSum
                                parameters:parameters
                        isImplicitlyLogged:NO
                                   session:session];
}


+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(double)valueToSum
              parameters:(NSDictionary *)parameters
                 session:(FBSession *)session {
    
    // Can only implicitly log Insights if either clientToken is established...
    BOOL canLog = [FBSettings clientToken] != nil;
    
    // ...or the specified Session is open (or it's nil and the activeSession is
    // open) so we have somewhere to log to...
    if (!canLog) {
        if (session) {
            canLog = session.isOpen;
        } else {
            canLog = [FBSession activeSessionIfOpen] != nil;
        }
    }
    
    // ...or if this is one of the events that can be logged to the endpoint without
    // an access token.
    if (!canLog) {
        canLog = [FBInsights.singleton.eventsNotRequiringToken containsObject:eventName];
    }
    
    if (canLog) {
        [FBInsights.singleton instanceLogEvent:eventName
                                    valueToSum:valueToSum
                                    parameters:parameters
                            isImplicitlyLogged:YES
                                       session:session];
    }
}

#pragma mark - logPurchase variants

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency {
    [FBInsights logPurchase:purchaseAmount
                   currency:currency
                 parameters:nil];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters {
    [FBInsights logPurchase:purchaseAmount
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
        newParameters = @{ FBInsightsEventParameterCurrency : currency };
    } else {
        newParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [newParameters setValue:currency forKey:FBInsightsEventParameterCurrency];
    }
    
    [FBInsights logEvent:FBInsightsEventNamePurchase
              valueToSum:purchaseAmount
              parameters:newParameters
                 session:session];
    
    // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since purchase events
    // are relatively rare and relatively high value and worth getting across on wire right away.
    if ([FBInsights flushBehavior] != FBInsightsFlushBehaviorExplicitOnly) {
        [FBInsights.singleton instanceFlush:FlushReasonEagerlyFlushingEvent];
    }
    
}

#pragma mark - {start/end}TimedEvent variants

+ (void)startTimedEvent:(NSString *)eventName {
    [FBInsights startTimedEvent:eventName
                     parameters:nil];
}

+ (void)startTimedEvent:(NSString *)eventName
                timerID:(NSString *)timerID {
    [FBInsights startTimedEvent:eventName
                     parameters:nil
                        timerID:timerID];
}

+ (void)startTimedEvent:(NSString *)eventName
             parameters:(NSDictionary *)parameters {
    [FBInsights startTimedEvent:eventName
                     parameters:parameters
                        timerID:nil];
}

+ (void)startTimedEvent:(NSString *)eventName
             parameters:(NSDictionary *)parameters
                timerID:(NSString *)timerID {
    [FBInsights.singleton instanceStartTimedEvent:eventName
                                       parameters:parameters
                                          timerID:timerID];
}

/*
 * Completion for timed events
 */
+ (void)logTimedEvent:(NSString *)eventName {
    [FBInsights logTimedEvent:eventName
                   parameters:nil];
}

+ (void)logTimedEvent:(NSString *)eventName
              timerID:(NSString *)timerID {
    [FBInsights logTimedEvent:eventName
                   parameters:nil
                      timerID:timerID];
}

+ (void)logTimedEvent:(NSString *)eventName
           parameters:(NSDictionary *)parameters {
    [FBInsights logTimedEvent:eventName
                   parameters:parameters
                      timerID:nil];
}

+ (void)logTimedEvent:(NSString *)eventName
           parameters:(NSDictionary *)parameters
               timerID:(NSString *)timerID {
    [FBInsights logTimedEvent:eventName
                   parameters:parameters
                      timerID:timerID
                      session:nil];
}

+ (void)logTimedEvent:(NSString *)eventName
           parameters:(NSDictionary *)parameters
              timerID:(NSString *)timerID
              session:(FBSession *)session {
    [FBInsights.singleton instanceLogTimedEvent:eventName
                                     parameters:parameters
                                        timerID:timerID
                                        session:session];
}

#pragma mark - Conversion Pixels

+ (void)logConversionPixel:(NSString *)pixelID
              valueOfPixel:(double)value {
    [FBInsights logConversionPixel:pixelID
                      valueOfPixel:value
                           session:nil];
}

+ (void)logConversionPixel:(NSString *)pixelID
              valueOfPixel:(double)value
                   session:(FBSession *)session {
    
    // This method exists to allow a single API to be invoked to log a conversion pixel from a native mobile app
    // (and thus readily included in a snippet).  It logs the event with known event name and parameter names.
    // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since pixel firings 
    // are relatively rare and relatively high value and worth getting across on wire right away.
    
    if (!pixelID) {
        [FBInsights logAndNotify:@"Conversion Pixel ID cannot be nil"];
        return;
    }
    
    [FBInsights logEvent:FBInsightsEventNameLogConversionPixel
              valueToSum:value
              parameters:@{ FBInsightsEventParameterConversionPixelID : pixelID,
                            FBInsightsEventParameterConversionPixelValue : [NSNumber numberWithDouble:value] }
                 session:session];
    
    if ([FBInsights flushBehavior] != FBInsightsFlushBehaviorExplicitOnly) {
        [FBInsights.singleton instanceFlush:FlushReasonEagerlyFlushingEvent];
    }
}

#pragma mark - Flushing & Session Management

+ (FBInsightsFlushBehavior)flushBehavior {
    return FBInsights.singleton.flushBehavior;
}

+ (void)setFlushBehavior:(FBInsightsFlushBehavior)flushBehavior {
    FBInsights.singleton.flushBehavior = flushBehavior;
}

+ (void)flush {
    [FBInsights.singleton instanceFlush:FlushReasonExplicit];
}

#pragma mark - Private Methods


+ (FBInsights *)singleton {
    static dispatch_once_t pred;
    static FBInsights *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[FBInsights alloc] init];
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
 * FBSessionInsightsState is a chunk of state that hangs off of FBSession and holds event state
 * destined for that session.
 *
 * That FBSessionInsightsState instance itself is used as the synchronization object for most logging
 * state.  For multi-thread accessed global state, we synchronize mostly on the FBInsights singleton object.
 *
 * The other singleton state is intended to be accessed from the main thread only (though certain ones, like
 * flushBehavior, are innocuous enough that it doesn't matter).
 *
 * Every method here that is expected to be called from the main thread should have
 * [FBInsights ensureOnMainThread] at its top.  This just does an FBConditionalLog if it's not the main thread,
 * but indicates a clear logic error in how this is being used when that occurs.
 */


- (FBInsights *)init {
    self = [super init];
    if (self) {
        self.haveOutstandingPersistedData = NO;
        self.flushBehavior = FBInsightsFlushBehaviorAuto;
        self.appSupportsAttributionStatus = AppSupportsAttributionUnknown;

        self.incompleteTimedEvents = [[[NSMutableDictionary alloc] init] autorelease];
        self.appAuthSessions = [[[NSMutableDictionary alloc] init] autorelease];
        
        // Timer fires unconditionally on a regular interval... handler decides whether to call flush.
        self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:FLUSH_PERIOD_IN_SECONDS
                                                           target:self
                                                         selector:@selector(flushTimerFired:)
                                                         userInfo:nil
                                                          repeats:YES];
        
        self.attributionIDRecheckTimer = [NSTimer scheduledTimerWithTimeInterval:APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD
                                                                          target:self
                                                                        selector:@selector(attributionIDRecheckTimerFired:)
                                                                        userInfo:nil
                                                                         repeats:YES];
        
        // These events may be logged when there's no clientToken-based or user-session based
        // access token since they represent events that may occur implicitly when there's no one
        // logged in.  
        self.eventsNotRequiringToken = [NSSet setWithArray:@[ FBInsightsEventNameShareSheetLaunch,
                                                              FBInsightsEventNameShareSheetDismiss,
                                                              FBInsightsEventNamePermissionsUILaunch,
                                                              FBInsightsEventNamePermissionsUIDismiss,
                                                              FBInsightsEventNameFBDialogsCanPresentShareDialog,
                                                              FBInsightsEventNameFBDialogsCanPresentShareDialogOG,
                                                              FBInsightsEventNameFBDialogsNativeLoginDialogStart,
                                                              FBInsightsEventNameFBDialogsWebLoginCompleted]];
        
        // Register an observer to watch for app moving out of the active state, which we use
        // to signal a flush.  Since this is static, we don't unregister anywhere.
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationMovingFromActiveState)
         name:UIApplicationWillResignActiveNotification
         object:NULL];
        
        // Register for app termination, where we'll persist unsent events.
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationTerminating)
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

// Note: not implementing dealloc() here, as this is used as a singleton and is never expected to be released.


- (void)instanceLogEvent:(NSString *)eventName
              valueToSum:(double)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
                 session:(FBSession *)session {
    
    // For non-implicitly logged events, require a client token, and throw if there isn't one.  The app must establish this prior to
    // any calls to log.  While only needed for non-user-auth'd scenarios, we don't expect apps using Insights to require auth, so we
    // check this aggressively up front to avoid errors later on.
    if (!isImplicitlyLogged && ![FBSettings clientToken]) {
        [FBInsights raiseInvalidOperationException:
            @"FBInsights: Must set a client token with [FBSettings setClientToken] in order to log FBInsights events."];
    };
    
    // Bail out of implicitly logged events if we know we're not doing implicit logging.
    if (isImplicitlyLogged && self.haveFetchedAppSettings && !self.appSupportsImplicitLogging) {
        return;
    }
    
    // Push the event onto the queue for later flushing.
    
    __block BOOL failed = NO;
    
    // Make sure parameter dictionary is well formed.  Log and exit if not.
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        if (![key isKindOfClass:[NSString class]]) {
            [FBInsights logAndNotify:[NSString stringWithFormat:@"The keys in the parameters must be NSStrings, '%@' is not.", key]];
            failed = YES;
        }
        
        if (![obj isKindOfClass:[NSString class]] && ![obj isKindOfClass:[NSNumber class]]) {
            [FBInsights logAndNotify:[NSString stringWithFormat:@"The values in the parameters dictionary must be NSStrings or NSNumbers, '%@' is not.", obj]];
            failed = YES;
        }
        
    }
     ];
    
    if (failed) {
        return;
    }
    
    FBSession *sessionToLogTo = [self sessionToSendRequestTo:session
                                                       appID:[FBSettings defaultAppID]
                                                 clientToken:[FBSettings clientToken]];
    
    NSMutableDictionary *eventDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    long logTime = [FBInsights unixTimeNow];
    [eventDictionary setObject:eventName forKey:@"_eventName"];
    [eventDictionary setObject:[NSNumber numberWithLong:logTime] forKey:@"_logTime"];
    
    if (valueToSum != 1.0) {
        [eventDictionary setObject:[NSNumber numberWithDouble:valueToSum] forKey:@"_valueToSum"];
    }
    
    @synchronized (self) {
        if (self.appVersion) {
            [eventDictionary setObject:self.appVersion forKey:@"_appVersion"];
        }
        
        // If this is a different session than the most recent we logged to, set up that earlier session for flushing, and update
        // the most recent.
        if (!self.lastSessionLoggedTo) {
            self.lastSessionLoggedTo = sessionToLogTo;
        }
        
        if (self.lastSessionLoggedTo != sessionToLogTo) {
            // Since we're not logging to lastSessionLoggedTo, at least for now, set it up for flushing.  If we swap back and
            // forth frequently between sessions, this could be thrashy, but that's not an expected use case of the SDK.
            [self flush:FlushReasonSessionChange session:self.lastSessionLoggedTo];
            self.lastSessionLoggedTo = sessionToLogTo;
        }
        
        FBSessionInsightsState *insightsState = sessionToLogTo.insightsState;
        
        [insightsState addEvent:eventDictionary isImplicit:isImplicitlyLogged];
        
        BOOL eventsRetrievedFromPersistedData = NO;
        if (self.haveOutstandingPersistedData) {
            // Now that we have a session, we can read in our persisted data.
            eventsRetrievedFromPersistedData = [self updateInsightsStateWithPersistedData:sessionToLogTo];
            self.haveOutstandingPersistedData = NO;
        }
        
        if (self.flushBehavior != FBInsightsFlushBehaviorExplicitOnly) {
            
            if (insightsState.getAccumulatedEventCount > NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER) {
                [self flush:FlushReasonEventThreshold session:sessionToLogTo];
            } else if (eventsRetrievedFromPersistedData) {
                [self flush:FlushReasonPersistedEvents session:sessionToLogTo];
            }
            
        }
    }
}

// generate per event, per timer id, per thread key to identify the timed event instance.
+ (NSString *)constructTimerKey:(NSString *)eventName
                        timerID:(NSString *)timerID {
    return [NSString stringWithFormat:@"%@|%@|%@", eventName, timerID, [NSThread currentThread]];
}

- (void)instanceStartTimedEvent:(NSString *)eventName
                     parameters:(NSDictionary *)parameters
                        timerID:(NSString *)timerID {
    
    // Put in list of "timed events" waiting for completion.
    long startTime = [FBInsights unixTimeNow];
    
    NSDictionary *timedEventDictionary;
    if (parameters) {
        timedEventDictionary = @{ @"startTime"  : [NSNumber numberWithLong:startTime],
                                  @"parameters" : parameters };
    } else {
        timedEventDictionary = @{ @"startTime"  : [NSNumber numberWithLong:startTime] };
    }
    
    NSString *key = [FBInsights constructTimerKey:eventName timerID:timerID];
    
    @synchronized (self.incompleteTimedEvents) {
        if ([self.incompleteTimedEvents objectForKey:key]) {
            [FBInsights logAndNotify:[NSString stringWithFormat:@"Timed event for '%@' has already been started with timerID '%@' on this thread",
                                      eventName, timerID]];
            return;
        }
        
        [self.incompleteTimedEvents setObject:timedEventDictionary forKey:key];
    }
}

- (void)instanceLogTimedEvent:(NSString *)eventName
                   parameters:(NSDictionary *)parameters
                      timerID:(NSString *)timerID
                      session:(FBSession *)session {
    
    NSString *key = [FBInsights constructTimerKey:eventName timerID:timerID];
    
    NSDictionary *storedTimedEvent = nil;
    @synchronized (self.incompleteTimedEvents) {
        // Look up start time based on key, then fixup params, and log event.
        if (!(storedTimedEvent = [[[self.incompleteTimedEvents objectForKey:key] retain] autorelease])) {
            [FBInsights logAndNotify:[NSString stringWithFormat:@"Timed event for '%@' and timerID '%@' has not yet been started on this thread",
                                      eventName, timerID]];
            return;
        }
        
        // Don't need in our 'incomplete events' list any longer (will decref, hence the retain above).
        [self.incompleteTimedEvents removeObjectForKey:key];
    }
    
    // Update all the parameters in the storedTimedEvent with those coming in in parameters.
    NSDictionary *storedParameters = [storedTimedEvent objectForKey:@"parameters"];
    NSMutableDictionary *resultParameters;
    if (storedParameters) {
        resultParameters = [NSMutableDictionary dictionaryWithDictionary:storedParameters];
    } else {
        resultParameters = [NSMutableDictionary dictionary];
    }
    
    if (parameters) {
        [resultParameters addEntriesFromDictionary:parameters];
    }
    
    // Pass down the fact that this event is to be interpreted as a 'timed event'.
    [resultParameters setValue:@"1" forKey:@"_isTimedEvent"];
    
    // And let the value become the elapsed time.
    long startTime = [[storedTimedEvent objectForKey:@"startTime"] longValue];
    long elapsedTime = [FBInsights unixTimeNow] - startTime;
    
    [self instanceLogEvent:eventName
                valueToSum:(double)elapsedTime
                parameters:resultParameters
        isImplicitlyLogged:NO
                   session:session];
}



- (void)instanceFlush:(FlushReason)flushReason {
    if (self.lastSessionLoggedTo) {  // nil only if no logging yet, instanceLogEvent will fill this in.
        [self flush:flushReason session:self.lastSessionLoggedTo];
    }
}


- (void)flush:(FlushReason)flushReason
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
 
 - always executing on the main thread, and the flush is targeted at the insightsState on the session
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
- (void)flushOnMainQueue:(FlushReason)flushReason
                 session:(FBSession *)session {
    
    [FBInsights ensureOnMainThread];
    FBSessionInsightsState *insightsState = session.insightsState;
    
    // If trying to flush a session already in flight, just ignore and continue to accum events
    // until we try to flush again.
    if (insightsState.requestInFlight || self.appSupportsAttributionStatus == AppSupportsAttributionQueryInFlight) {
        return;
    }
    
    NSString *appid = [FBSettings defaultAppID];
    
    if (self.appSupportsAttributionStatus == AppSupportsAttributionUnknown) {
        
        // If we haven't yet determined whether the app supports sending the attribution ID, we'll need
        // to make an initial request to determine this, and then call back in once we know.
        self.appSupportsAttributionStatus = AppSupportsAttributionQueryInFlight;
        [FBUtility fetchAppSettings:appid
                           callback:^(FBFetchedAppSettings *settings, NSError *error) {
                               
                               [FBInsights ensureOnMainThread];
                   
                               // Treat an error as if the app doesn't allow sending of attribution ID.
                               self.appSupportsAttributionStatus = settings.supportsAttribution && !error
                                 ? AppSupportsAttributionTrue : AppSupportsAttributionFalse;
                    
                               self.appSupportsImplicitLogging = settings.supportsImplicitSdkLogging;
                               
                               self.haveFetchedAppSettings = YES;
                             
                               // Kick off the original flush, now that we have the info we need.
                               [self flushOnMainQueue:flushReason session:session];
                           }
        ];

        return;
        
    } 
    
    NSString *jsonEncodedEvents;
    int eventCount, numSkipped, numAbandoned;
    @synchronized (insightsState) {
        
        [insightsState.inFlightEvents addObjectsFromArray:insightsState.accumulatedEvents];
        [insightsState.accumulatedEvents removeAllObjects];
        eventCount = insightsState.inFlightEvents.count;
        
        if (!eventCount) {
            return;
        }
        
        jsonEncodedEvents = [insightsState jsonEncodeInFlightEvents:self.appSupportsImplicitLogging];
        numSkipped = insightsState.numSkippedEventsDueToFullBuffer;
        numAbandoned = insightsState.numAbandonedDueToSessionChange;
    }
    
    // Move custom events field off the URL and into a POST field only by encoding into UTF8, which the server
    // will then handle as an uploaded file.  It also allows request compression to work on event data.
    NSData *utf8EncodedEvents = [jsonEncodedEvents dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!utf8EncodedEvents) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorInsights
                            logEntry:@"FBInsights: Flushing skipped - no events after removing implicitly logged ones.\n"];
        return;
    }
    
    NSMutableDictionary *postParameters =
        [NSMutableDictionary dictionaryWithDictionary:
            @{ @"event" : @"CUSTOM_APP_EVENTS",
               @"custom_events_file" : utf8EncodedEvents,
               @"num_skipped_events" : [NSString stringWithFormat:@"%d", numSkipped],
               @"num_abandoned_events" : [NSString stringWithFormat:@"%d", numAbandoned],
            }
         ];
    
    [self optionallyAppendAttributionAndAdvertiserIDs:postParameters
                                              session:session];
        
    [FBLogger singleShotLogEntry:FBLoggingBehaviorInsights
                    formatString:@"FBInsights: Flushing @ %ld, %d events due to %u - %@\n%@",
                        [FBInsights unixTimeNow],
                        eventCount,
                        flushReason,
                        postParameters,
                        jsonEncodedEvents];
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session
                                                   graphPath:[NSString stringWithFormat:@"%@/activities", appid]
                                                  parameters:postParameters
                                                  HTTPMethod:@"POST"] autorelease];
    
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self handleActivitiesPostCompletion:error
                                 flushReason:flushReason
                                     session:session];
    }];
    
    insightsState.requestInFlight = YES;
}

- (void)optionallyAppendAttributionAndAdvertiserIDs:(NSMutableDictionary *)postParameters
                                            session:(FBSession *)session {

    if ([self doesSessionHaveUserToken:session]) {
        // We have a logged in user token, and there's no point in sending attribution id or advertiser id.
        return;
    }
    
    if (self.appSupportsAttributionStatus == AppSupportsAttributionTrue) {
        NSString *attributionID = [FBUtility attributionID];
        if (attributionID) {
            [postParameters setObject:attributionID forKey:@"attribution"];
        }
    }
    
    // Send advertiserID if available, and send along whether tracking is enabled too.  That's because
    // we can use the advertiser_id for non-tracking purposes (aggregated Insights/demographics) that doesn't
    // result in advertising targeting that user.
    NSString *advertiserID = [FBUtility advertiserID];
    if (advertiserID) {
        [postParameters setObject:advertiserID forKey:@"advertiser_id"];
    }
    
    [FBUtility updateParametersWithAdvertisingTrackingStatus:postParameters];
}

- (BOOL)doesSessionHaveUserToken:(FBSession *)session {
    // Assume that if we're not using an appAuthSession (built from the Client Token) or the anonymous session,
    // then we have a logged in user token.
    FBSession *appAuthSession = [self.appAuthSessions objectForKey:session.appID];
    return session != appAuthSession && session != self.anonymousSession;
}


// Given a candidate session (which may be nil), find the real session to send the FBRequest to (with an access token).
// Precedence: 1) provided session, 2) activeSession, 3) app authenticated session, 4) fully anonymous session
- (FBSession *)sessionToSendRequestTo:(FBSession *)session
                                appID:(NSString *)appID
                          clientToken:(NSString *)clientToken {
    
    if (!session) {
        session = [FBSession activeSession];
    }
    
    if (!session.accessTokenData.accessToken) {

        if (clientToken) {
            
            FBSession *appAuthSession = [self.appAuthSessions objectForKey:appID];
            if (!appAuthSession) {
                
                @synchronized(self) {
                    
                    appAuthSession = [self.appAuthSessions objectForKey:appID];  // in case it snuck in
                    if (!appAuthSession) {  
                
                        FBSessionManualTokenCachingStrategy *tokenCaching = [[FBSessionManualTokenCachingStrategy alloc] init];
                        tokenCaching.accessToken = [NSString stringWithFormat:@"%@|%@", appID, clientToken];
                        tokenCaching.expirationDate = [NSDate dateWithTimeIntervalSinceNow:315360000]; // 10 years from now
                        
                        // Create session with explicit token and stash with appID.
                        appAuthSession = [FBInsights unaffinitizedSessionFromToken:tokenCaching];
                        [tokenCaching release];
                        
                        [self.appAuthSessions setObject:appAuthSession forKey:appID];
                    }
                }
            }
            session = appAuthSession;
            
        } else {
            
            // No clientToken, create session without access token that can be used for logging the events in 'eventsNotRequiringToken'
            if (!self.anonymousSession) {
                
                @synchronized(self) {
                    
                    if (!self.anonymousSession) {  // in case it snuck in
                        self.anonymousSession = [FBInsights unaffinitizedSessionFromToken:[FBSessionTokenCachingStrategy nullCacheInstance]];
                    }
                }
            }
            session = self.anonymousSession;
        }
            
    }
    
    return session;
}

+ (FBSession *)unaffinitizedSessionFromToken:(FBSessionTokenCachingStrategy *)tokenCachingStrategy {

    FBSession *session = [[[FBSession alloc] initWithAppID:nil
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
                           flushReason:(FlushReason)flushReason
                               session:(FBSession *)session {
    
    typedef enum {
        FlushResultSuccess,
        FlushResultServerError,
        FlushResultNoConnectivity
    } FlushResult;
    
    [FBInsights ensureOnMainThread];
    
    FlushResult flushResult = FlushResultSuccess;
    if (error) {
        
        int errorCode = [[[error userInfo] objectForKey:FBErrorHTTPStatusCodeKey] integerValue];
        
        // We interpret a 400 coming back from FBRequestConnection as a server error due to improper data being
        // sent down.  Otherwise we assume no connectivity, or another condition where we could treat it as no connectivity.
        flushResult = errorCode == 400 ? FlushResultServerError : FlushResultNoConnectivity;
    }
    
    FBSessionInsightsState *insightsState = session.insightsState;
    @synchronized (insightsState) {
        if (flushResult != FlushResultNoConnectivity) {
            
            // Either success or a real server error.  Either way, no more in flight events.
            [insightsState clearInFlightAndStats];
        }
        
        insightsState.requestInFlight = NO;
    }

    if (flushResult == FlushResultServerError) {
        [FBInsights logAndNotify:[error description]];
    }
}


- (void)flushTimerFired:(id)arg {
    [FBInsights ensureOnMainThread];
    
    @synchronized (self) {
        if (self.flushBehavior != FBInsightsFlushBehaviorExplicitOnly) {
            if (self.lastSessionLoggedTo.insightsState.inFlightEvents.count > 0 ||
                self.lastSessionLoggedTo.insightsState.accumulatedEvents.count > 0) {
            
                [self flush:FlushReasonTimer session:self.lastSessionLoggedTo];
            }
        }
    }
}

- (void)attributionIDRecheckTimerFired:(id)arg {
    // Reset app attribution status so it will be re-fetched in the event there was a server change.
    self.appSupportsAttributionStatus = AppSupportsAttributionUnknown;
}

- (void)applicationDidBecomeActive {
    
    [FBInsights ensureOnMainThread];
    
    // We associate the deserialized persisted data with the current session.
    // It's possible we'll get false attribution if the user identity has changed
    // between the time the data was persisted and now, but we'll accept these
    // anomolies in the aggregate data (which should be rare anyhow).
    
    // Can only actively update state and log when we have a session, otherwise we
    // set a BOOL to tell us to update as soon as we can afterwards.
    if (self.lastSessionLoggedTo) {
        
        BOOL eventsRetrieved = [self updateInsightsStateWithPersistedData:self.lastSessionLoggedTo];
        
        if (eventsRetrieved && self.flushBehavior != FBInsightsFlushBehaviorExplicitOnly) {
            [self flush:FlushReasonPersistedEvents session:self.lastSessionLoggedTo];
        }
        
    } else {
        
        self.haveOutstandingPersistedData = YES;
        
    }
}

// Read back previously persisted events, if any, into specified session, returning whether any events were retrieved.
- (BOOL)updateInsightsStateWithPersistedData:(FBSession *)session {
    
    BOOL eventsRetrieved = NO;
    NSDictionary *persistedData = [FBInsights retrievePersistedInsightsData];
    if (persistedData) {
        
        [FBInsights clearPersistedInsightsData];
        
        FBSessionInsightsState *insightsState = session.insightsState;        
        @synchronized (insightsState) {
            insightsState.numAbandonedDueToSessionChange += [[persistedData objectForKey:FBInsightsPersistKeyNumAbandoned] integerValue];
            insightsState.numSkippedEventsDueToFullBuffer += [[persistedData objectForKey:FBInsightsPersistKeyNumSkipped] integerValue];
            NSArray *retrievedObjects = [persistedData objectForKey:FBInsightsPersistKeyEvents];
            if (retrievedObjects.count) {
                [insightsState.inFlightEvents addObjectsFromArray:retrievedObjects];
                eventsRetrieved = YES;
            }
        }
    }
    
    return eventsRetrieved;
}

- (void)applicationMovingFromActiveState {
    // When moving from active state, we don't have time to wait for the result of a flush, so
    // just persist events to storage, and we'll process them at the next activation.
    [self persistDataIfNotInFlight];
}

- (void)applicationTerminating {
    // When terminating, we don't have time to wait for the result of a flush, so
    // just persist events to storage, and we'll process them at the next activation.
    [self persistDataIfNotInFlight];
}

- (void)persistDataIfNotInFlight {
    [FBInsights ensureOnMainThread];

    FBSessionInsightsState *insightsState = self.lastSessionLoggedTo.insightsState;
    if (insightsState.requestInFlight) {
        // In flight request may or may not succeed, so there's no right thing to do here.  Err by just not doing anything on termination;
        return;
    }
    
    // Persist right away if needed (rather than trying one last sync) since we're about to be booted out.
    [FBInsights persistInsightsData:insightsState];
}

+ (void)logAndNotify:(NSString *)msg {
    
    // capture reason and nested code as user info
    NSDictionary* userinfo = [NSDictionary dictionaryWithObject:msg forKey:FBErrorInsightsReasonKey];
    
    // create error object
    NSError *err = [NSError errorWithDomain:FacebookSDKDomain
                                       code:FBErrorInsights
                                   userInfo:userinfo];
    
    [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:msg];

    [[NSNotificationCenter defaultCenter] postNotificationName:FBInsightsLoggingResultNotification
                                                        object:err];
}

#pragma mark - event log persistence

+ (void)persistInsightsData:(FBSessionInsightsState *)insightsState {
    
    [FBInsights ensureOnMainThread];
    NSString *content;
    
    // We just persist from the last session being logged to.  When we switch sessions, we flush out
    // the one being moved away from.  So, modulo in-flight sessions, the only one with real data will
    // be the last one.
    
    @synchronized (insightsState) {
        [insightsState.inFlightEvents addObjectsFromArray:insightsState.accumulatedEvents];
        [insightsState.accumulatedEvents removeAllObjects];
        
        [FBLogger singleShotLogEntry:FBLoggingBehaviorInsights
                        formatString:@"FBInsights Persist: Writing %d events", insightsState.inFlightEvents.count];
        
        if (!insightsState.inFlightEvents.count) {
            return;
        }
        
        NSDictionary *insightsData = @{
            FBInsightsPersistKeyNumAbandoned : [NSNumber numberWithInt:insightsState.numAbandonedDueToSessionChange],
            FBInsightsPersistKeyNumSkipped   : [NSNumber numberWithInt:insightsState.numSkippedEventsDueToFullBuffer],
            FBInsightsPersistKeyEvents       : insightsState.inFlightEvents,
        };

        content = [FBUtility simpleJSONEncode:insightsData];
        
        [insightsState clearInFlightAndStats];
    }
    
    //save content to the documents directory
    [content writeToFile:[FBInsights persistenceFilePath]
              atomically:YES
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];

}

+ (NSDictionary *)retrievePersistedInsightsData {
        
    NSString *content = [[NSString alloc] initWithContentsOfFile:[FBInsights persistenceFilePath]
                                                    usedEncoding:nil
                                                           error:nil];
    NSDictionary *results = [FBUtility simpleJSONDecode:content];
    [content release];
    
    [FBLogger singleShotLogEntry:FBLoggingBehaviorInsights
                    formatString:@"FBInsights Persist: Read %d events", results ? [[results objectForKey:FBInsightsPersistKeyEvents] count] : 0];
    return results;
}

+ (void)clearPersistedInsightsData {
    
    [FBLogger singleShotLogEntry:FBLoggingBehaviorInsights
                        logEntry:@"FBInsights Persist: Clearing"];
    [[NSFileManager defaultManager] removeItemAtPath:[FBInsights persistenceFilePath] error:nil];
}

+ (NSString *)persistenceFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    return [docDirectory stringByAppendingPathComponent:FBInsightsPersistedEventsFilename];
}

+ (void)ensureOnMainThread {
    FBConditionalLog([NSThread isMainThread], @"*** This method expected to be called on the main thread.");
}

+ (void)raiseInvalidOperationException:(NSString *)reason {
    [[NSException exceptionWithName:FBInvalidOperationException
                             reason:reason
                           userInfo:nil]
     raise];
}


#pragma mark - Custom Audience token stuff

// This code lives here in Insights because it shares many of the runtime characteristics of the Insights logging,
// even though the public exposure is elsewhere

+ (FBRequest *)customAudienceThirdPartyIDRequest:(FBSession *)session {
    return [FBInsights.singleton instanceCustomAudienceThirdPartyIDRequest:session];
}


- (FBRequest *)instanceCustomAudienceThirdPartyIDRequest:(FBSession *)session {
    
    // Require an appID and clientToken, and throw if either aren't present.  Throw because this is almost certainly a
    // developer time error that won't have runtime variation, and must be fixed.
    NSString *appID = [FBSettings defaultAppID];
    if (!appID) {
        [FBInsights raiseInvalidOperationException:
            @"customAudienceThirdPartyID: Must set an appID, or have one set in the app's pList in order to get a Custom Audience  Third Party ID back."];
    }
    
    NSString *clientToken = [FBSettings clientToken];
    if (!clientToken) {
        [FBInsights raiseInvalidOperationException:
            @"customAudienceThirdPartyID: Must have a clientToken set via [FBSettings setClientToken:] in order to get a Custom Audience Third Party ID back."];
    }
    
    // Rules for how we use the attribution ID / advertiser ID for an 'custom_audience_third_party_id' Graph API request
    // 1) if the OS tells us that the user has Limited Ad Tracking, then just don't send, and return a nil in the token.
    // 2) if we have a user session token, then no need to send attribution ID / advertiser ID back as the udid parameter
    // 3) otherwise, send back the udid parameter.
    
    if ([FBUtility advertisingTrackingStatus] == AdvertisingTrackingDisallowed) {
        return nil;
    }
    
    FBSession *sessionToSendRequestTo = [self sessionToSendRequestTo:session
                                                               appID:appID
                                                         clientToken:clientToken];
    
    NSString *udid = nil;
    if (![self doesSessionHaveUserToken:sessionToSendRequestTo]) {
        
        // We don't have a logged in user, so we need some form of udid representation.  Prefer
        // advertiser ID if available, and back off to attribution ID if not.
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
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:sessionToSendRequestTo
                                                   graphPath:@"custom_audience_third_party_id"
                                                  parameters:parameters
                                                  HTTPMethod:nil]
                          autorelease];
       
    return request;
}

@end
