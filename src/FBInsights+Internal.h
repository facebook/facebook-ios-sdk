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

#import "FBInsights.h"

@class FBRequest;

// Internally known event names

/*! Use to log that the share dialog was launched */
extern NSString *const FBInsightsEventNameShareSheetLaunch;

/*! Use to log that the share dialog was dismissed */
extern NSString *const FBInsightsEventNameShareSheetDismiss;

/*! Use to log that the permissions UI was launched */
extern NSString *const FBInsightsEventNamePermissionsUILaunch;

/*! Use to log that the permissions UI was dismissed */
extern NSString *const FBInsightsEventNamePermissionsUIDismiss;

/*! Use to log that the friend picker was launched and completed */
extern NSString *const FBInsightsEventNameFriendPickerUsage;

/*! Use to log that the place picker dialog was launched and completed */
extern NSString *const FBInsightsEventNamePlacePickerUsage;

// Internally known event parameters

/*! String parameter specifying the outcome of a dialog invocation */
extern NSString *const FBInsightsEventParameterDialogOutcome;

/*! Use to log the result of a call to FBDialogs canPresentShareDialogWithParams: */
extern NSString *const FBInsightsEventNameFBDialogsCanPresentShareDialog;

/*! Use to log the result of a call to FBDialogs canPresentShareDialogWithOpenGraphActionParams: */
extern NSString *const FBInsightsEventNameFBDialogsCanPresentShareDialogOG;

/*! Use to log the timestamp for the transition to the Facebook native login dialog */
extern NSString *const FBInsightsEventNameFBDialogsNativeLoginDialogStart;

/*! Use to log the e2e timestamp metrics for web login */
extern NSString *const FBInsightsEventNameFBDialogsWebLoginCompleted;

// Internally known event parameter values

extern NSString *const FBInsightsDialogOutcomeValue_Completed;
extern NSString *const FBInsightsDialogOutcomeValue_Cancelled;
extern NSString *const FBInsightsDialogOutcomeValue_Failed;

extern NSString *const FBInsightsNativeLoginDialogStartTime;

extern NSString *const FBInsightsWebLoginE2E;
extern NSString *const FBInsightsWebLoginSwitchbackTime;

@interface FBInsights (Internal)

+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(double)valueToSum
              parameters:(NSDictionary *)parameters
                 session:(FBSession *)session;

+ (FBRequest *)customAudienceThirdPartyIDRequest:(FBSession *)session;

@end
