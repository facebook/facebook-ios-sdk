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

#import "FBTimeSpentData.h"

#import "FBAppEvents+Internal.h"
#import "FBSettings.h"
#import "FBUtility.h"

// Filename and keys for session length
static NSString *const FBTimeSpentFilename                                    = @"com-facebook-sdk-AppEventsTimeSpent.json";
static NSString *const FBTimeSpentPersistKeySessionSecondsSpent               = @"secondsSpentInCurrentSession";
static NSString *const FBTimeSpentPersistKeySessionNumInterruptions           = @"numInterruptions";
static NSString *const FBTimeSpentPersistKeyLastSuspendTime                   = @"lastSuspendTime";

static NSString *const FBAppEventNameDeactivatedApp                           = @"fb_mobile_deactivate_app";
static NSString *const FBAppEventParameterNameSessionInterruptions            = @"fb_mobile_app_interruptions";
static NSString *const FBAppEventParameterNameTimeBetweenSessions             = @"fb_mobile_time_between_sessions";

static const int NUM_SECONDS_IDLE_TO_BE_NEW_SESSION = 60;
static const int SECS_PER_MIN                       = 60;
static const int SECS_PER_HOUR                      = 60 * SECS_PER_MIN;
static const int SECS_PER_DAY                       = 24 * SECS_PER_HOUR;

// Will be translated and displayed in App Insights.  Need to maintain same number and value of quanta on the server.
static const long INACTIVE_SECONDS_QUANTA[] = {
    5 * SECS_PER_MIN,
    15 * SECS_PER_MIN,
    30 * SECS_PER_MIN,
    1 * SECS_PER_HOUR,
    6 * SECS_PER_HOUR,
    12 * SECS_PER_HOUR,
    1 * SECS_PER_DAY,
    2 * SECS_PER_DAY,
    3 * SECS_PER_DAY,
    7 * SECS_PER_DAY,
    14 * SECS_PER_DAY,
    21 * SECS_PER_DAY,
    28 * SECS_PER_DAY,
    60 * SECS_PER_DAY,
    90 * SECS_PER_DAY,
    120 * SECS_PER_DAY,
    150 * SECS_PER_DAY,
    180 * SECS_PER_DAY,
    365 * SECS_PER_DAY,
    LONG_MAX,   // keep as LONG_MAX to guarantee loop will terminate
};

/**
 * This class encapsulates the notion of an app 'session' - the length of time that the user has
 * spent in the app that can be considered a single usage of the app.  Apps may be frequently interrupted
 * do to other device activity, like a text message, so this class allows those interruptions to be smoothed
 * out and the time actually spent in the app excluding this interruption time to be accumulated.  Also,
 * once a certain amount of time has gone by where the app is not in the foreground, we consider the
 * session to be complete, and a new session beginning.  When this occurs, we log an 'activate app' event
 * with the duration of the previous session as the 'value' of this event, along with the number of
 * interruptions from that previous session as an event parameter.
 */

@implementation FBTimeSpentData

BOOL _isCurrentlyLoaded;
BOOL _shouldLogActivateEvent;
BOOL _shouldLogDeactivateEvent;
long  _secondsSpentInCurrentSession;
long  _timeSinceLastSuspend;
int  _numInterruptionsInCurrentSession;
long _lastRestoreTime;

//
// Public methods
//

+ (void)suspend {
    [self.singleton instanceSuspend];
}

+ (void)restore:(BOOL)calledFromActivateApp {
    [self.singleton instanceRestore:calledFromActivateApp];
}

//
// Internal methods
//

+ (FBTimeSpentData *)singleton {
    static dispatch_once_t pred;
    static FBTimeSpentData *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[FBTimeSpentData alloc] init];
    });
    return shared;
}

// Calculate and persist time spent data for this instance of the app activation.
- (void)instanceSuspend {

    [FBAppEvents ensureOnMainThread];
    if (!_isCurrentlyLoaded) {
        FBConditionalLog(YES, FBLoggingBehaviorInformational, @"[FBTimeSpentData suspend] invoked without corresponding restore");
        return;
    }

    long now = [FBAppEvents unixTimeNow];
    long timeSinceRestore = now - _lastRestoreTime;

    // Can happen if the clock on the device is changed
    if (timeSinceRestore < 0) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                        formatString:@"Clock skew detected"];
        timeSinceRestore = 0;
    }

    _secondsSpentInCurrentSession += timeSinceRestore;

    NSDictionary *timeSpentData =
        @{
          FBTimeSpentPersistKeySessionSecondsSpent : @(_secondsSpentInCurrentSession),
          FBTimeSpentPersistKeySessionNumInterruptions : @(_numInterruptionsInCurrentSession),
          FBTimeSpentPersistKeyLastSuspendTime : @(now)
        };

    NSString *content = [FBUtility simpleJSONEncode:timeSpentData];

    [content writeToFile:[FBAppEvents persistenceLibraryFilePath:FBTimeSpentFilename]
              atomically:YES
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];

    [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                    formatString:@"FBTimeSpentData Persist: %@", content];

    _isCurrentlyLoaded = NO;
}


// Called during activation - either through an explicit 'activateApp' call or implicitly when the app is foregrounded.
// In both cases, we restore the persisted event data.  In the case of the activateApp, we log an 'app activated'
// event if there's been enough time between the last deactivation and now.
- (void)instanceRestore:(BOOL)calledFromActivateApp {

    [FBAppEvents ensureOnMainThread];

    // It's possible to call this multiple times during the time the app is in the foreground.  If this is the case,
    // just restore persisted data the first time.
    if (!_isCurrentlyLoaded) {

        NSString *content =
          [[[NSString alloc] initWithContentsOfFile:[FBAppEvents persistenceLibraryFilePath:FBTimeSpentFilename]
                                      usedEncoding:nil
                                             error:nil]
           autorelease];

        [FBLogger singleShotLogEntry:FBLoggingBehaviorAppEvents
                        formatString:@"FBTimeSpentData Restore: %@", content];

        long now = [FBAppEvents unixTimeNow];
        if (!content) {

            // Nothing persisted, so this is the first launch.
            _secondsSpentInCurrentSession = 0;
            _numInterruptionsInCurrentSession = 0;

            // We want to log the app activation event on the first launch, but not the deactivate event
            _shouldLogActivateEvent = YES;
            _shouldLogDeactivateEvent = NO;

        } else {

            NSDictionary *results = [FBUtility simpleJSONDecode:content];
            long lastActiveTime = [[results objectForKey:FBTimeSpentPersistKeyLastSuspendTime] longValue];

            _timeSinceLastSuspend = now - lastActiveTime;
            _secondsSpentInCurrentSession = [[results objectForKey:FBTimeSpentPersistKeySessionSecondsSpent] intValue];
            _numInterruptionsInCurrentSession = [[results objectForKey:FBTimeSpentPersistKeySessionNumInterruptions] intValue];
            _shouldLogActivateEvent = (_timeSinceLastSuspend > NUM_SECONDS_IDLE_TO_BE_NEW_SESSION);

            // Other than the first launch, we always log the last session's deactivate with this session's activate.
            _shouldLogDeactivateEvent = _shouldLogActivateEvent;

            if (!_shouldLogDeactivateEvent) {
                // If we're not logging, then the time we spent deactivated is considered another interruption.  But cap it
                // so errant or test uses doesn't blow out the cardinality on the backend processing
                _numInterruptionsInCurrentSession = MIN(_numInterruptionsInCurrentSession + 1, 200);
            }

        }

        _lastRestoreTime = now;
        _isCurrentlyLoaded = YES;

        if (calledFromActivateApp) {

            if (_shouldLogActivateEvent) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"  // event name has been deprecated
                [FBAppEvents logEvent:FBAppEventNameActivatedApp
                           parameters:@{
                                        FBAppEventParameterLaunchSource: [FBAppEvents getSourceApplication]
                                        }];
#pragma clang diagnostic pop
            }

            if (_shouldLogDeactivateEvent) {

                int quantaIndex = 0;
                while (_timeSinceLastSuspend > INACTIVE_SECONDS_QUANTA[quantaIndex]) {
                    quantaIndex++;
                }

                [FBAppEvents logEvent:FBAppEventNameDeactivatedApp
                           valueToSum:_secondsSpentInCurrentSession
                           parameters:
                            @{ FBAppEventParameterNameSessionInterruptions : @(_numInterruptionsInCurrentSession),
                               FBAppEventParameterNameTimeBetweenSessions : [NSString stringWithFormat:@"session_quanta_%d", quantaIndex],
                               FBAppEventParameterLaunchSource: [FBAppEvents getSourceApplication],
                            }
                 ];

                // We've logged the session stats, now reset.
                _secondsSpentInCurrentSession = 0;
                _numInterruptionsInCurrentSession = 0;
            }
        }
    }

}

@end
