// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if defined FBSDK_SWIFT_PACKAGE
 #import "FBSDKAppEvents.h"
#else
 #import <FBSDKCoreKit/FBSDKAppEvents.h>
#endif

#import <UIKit/UIApplication.h>

#import "FBSDKAppEventsUtility.h"

@protocol FBSDKEventProcessing;
@protocol FBSDKMetadataIndexing;

// Internally known event names

/** Use to log that the share dialog was launched */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameShareSheetLaunch;

/** Use to log that the share dialog was dismissed */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameShareSheetDismiss;

/** Use to log that the permissions UI was launched */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNamePermissionsUILaunch;

/** Use to log that the permissions UI was dismissed */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNamePermissionsUIDismiss;

/** Use to log that the share tray launched. */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameShareTrayDidLaunch;

/** Use to log that the person selected a sharing target. */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameShareTrayDidSelectActivity;

// Internally known event parameters

/** Use to log the result of a call to FBDialogs presentShareDialogWithParams: */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBDialogsPresentShareDialog;

/** Use to log the result of a call to FBDialogs presentLikeDialogWithLikeParams: */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBDialogsPresentLikeDialogOG;

FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBDialogsPresentShareDialogPhoto;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBDialogsPresentMessageDialog;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBDialogsPresentMessageDialogPhoto;

/** Use to log the live streaming events from sdk */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingStart;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingStop;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingPause;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingResume;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingError;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingUpdateStatus;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingVideoID;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingMic;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingCamera;

/** Use to log the results of a share dialog */
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKEventAppInviteShareDialogResult;

FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKEventAppInviteShareDialogShow;

/** Use to log parameters for share tray use */
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterShareTrayActivityName;
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterShareTrayResult;

/** Use to log parameters for live streaming*/
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterLiveStreamingPrevStatus;
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterLiveStreamingStatus;
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterLiveStreamingError;
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterLiveStreamingVideoID;
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterLiveStreamingMicEnabled;
FOUNDATION_EXPORT NSString *const FBSDKAppEventParameterLiveStreamingCameraEnabled;

// Internally known event parameter values

FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Completed;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Failed;

FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLikeButtonImpression;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingButtonImpression;

FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLikeButtonDidTap;
FOUNDATION_EXPORT NSString *const FBSDKAppEventNameFBSDKLiveStreamingButtonDidTap;

FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesHandlerKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesActionKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesEventKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesParamsKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackCustomKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackSingleKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackSingleCustomKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelIDKey;

@interface FBSDKAppEvents (Internal)

@property (nonatomic) UIApplicationState applicationState;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
             accessToken:(FBSDKAccessToken *)accessToken;

- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;
- (void)startObservingApplicationLifecycleNotifications;

#if !TARGET_OS_TV

+ (void)configureNonTVComponentsWithOnDeviceMLModelManager:(id<FBSDKEventProcessing>)modelManager
                                           metadataIndexer:(id<FBSDKMetadataIndexing>)metadataIndexer;

#endif

@end
