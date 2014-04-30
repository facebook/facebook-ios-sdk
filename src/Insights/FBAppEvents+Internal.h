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
#import "FBSDKMacros.h"

@class FBRequest;

// Internally known event names

/*! Use to log that the share dialog was launched */
FBSDK_EXTERN NSString *const FBAppEventNameShareSheetLaunch;

/*! Use to log that the share dialog was dismissed */
FBSDK_EXTERN NSString *const FBAppEventNameShareSheetDismiss;

/*! Use to log that the permissions UI was launched */
FBSDK_EXTERN NSString *const FBAppEventNamePermissionsUILaunch;

/*! Use to log that the permissions UI was dismissed */
FBSDK_EXTERN NSString *const FBAppEventNamePermissionsUIDismiss;

/*! Use to log that the friend picker was launched and completed */
FBSDK_EXTERN NSString *const FBAppEventNameFriendPickerUsage;

/*! Use to log that the place picker dialog was launched and completed */
FBSDK_EXTERN NSString *const FBAppEventNamePlacePickerUsage;

/*! Use to log that the login view was used */
FBSDK_EXTERN NSString *const FBAppEventNameLoginViewUsage;

/*! Use to log that the user settings view controller was used */
FBSDK_EXTERN NSString *const FBAppEventNameUserSettingsUsage;

// Internally known event parameters

/*! String parameter specifying the outcome of a dialog invocation */
FBSDK_EXTERN NSString *const FBAppEventParameterDialogOutcome;

/*! Use to log the result of a call to FBDialogs presentShareDialogWithParams: */
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsPresentShareDialog;

/*! Use to log the result of a call to FBDialogs presentShareDialogWithOpenGraphActionParams: */
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsPresentShareDialogOG;

/*! Use to log the result of a call to FBDialogs presentLikeDialogWithLikeParams: */
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsPresentLikeDialogOG;

FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsPresentShareDialogPhoto;
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsPresentMessageDialog;
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsPresentMessageDialogPhoto;
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsPresentMessageDialogOG;

/*! Use to log the start of an auth request that cannot be fulfilled by the token cache */
FBSDK_EXTERN NSString *const FBAppEventNameFBSessionAuthStart;

/*! Use to log the end of an auth request that was not fulfilled by the token cache */
FBSDK_EXTERN NSString *const FBAppEventNameFBSessionAuthEnd;

/*! Use to log the start of a specific auth method as part of an auth request */
FBSDK_EXTERN NSString *const FBAppEventNameFBSessionAuthMethodStart;

/*! Use to log the end of the last tried auth method as part of an auth request */
FBSDK_EXTERN NSString *const FBAppEventNameFBSessionAuthMethodEnd;

/*! Use to log the timestamp for the transition to the Facebook native login dialog */
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsNativeLoginDialogStart;

/*! Use to log the timestamp for the transition back to the app after the Facebook native login dialog */
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsNativeLoginDialogEnd;

/*! Use to log the e2e timestamp metrics for web login */
FBSDK_EXTERN NSString *const FBAppEventNameFBDialogsWebLoginCompleted;

// Internally known event parameter values

FBSDK_EXTERN NSString *const FBAppEventsDialogOutcomeValue_Completed;
FBSDK_EXTERN NSString *const FBAppEventsDialogOutcomeValue_Cancelled;
FBSDK_EXTERN NSString *const FBAppEventsDialogOutcomeValue_Failed;

FBSDK_EXTERN NSString *const FBAppEventsNativeLoginDialogStartTime;
FBSDK_EXTERN NSString *const FBAppEventsNativeLoginDialogEndTime;

FBSDK_EXTERN NSString *const FBAppEventsWebLoginE2E;

typedef enum {
    FBAppEventsFlushReasonExplicit,
    FBAppEventsFlushReasonTimer,
    FBAppEventsFlushReasonSessionChange,
    FBAppEventsFlushReasonPersistedEvents,
    FBAppEventsFlushReasonEventThreshold,
    FBAppEventsFlushReasonEagerlyFlushingEvent
} FBAppEventsFlushReason;

@interface FBAppEvents (Internal)

+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
                 session:(FBSession *)session;

+ (FBRequest *)customAudienceThirdPartyIDRequest:(FBSession *)session;

// *** Expose internally for testing/mocking only ***
+ (FBAppEvents *)singleton;
- (void)handleActivitiesPostCompletion:(NSError *)error
                          loggingEntry:(NSString *)loggingEntry
                               session:(FBSession *)session;

+ (void)logConversionPixel:(NSString *)pixelID
              valueOfPixel:(double)value
                   session:(FBSession *)session;

- (void)instanceFlush:(FBAppEventsFlushReason)flushReason;

// *** end ***

@end
