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

#import <UIKit/UIApplication.h>

#import <FBSDKCoreKit/FBSDKAppEvents.h>

#import "FBSDKAppEventName.h"
#import "FBSDKAppEventsUtility.h"

NS_ASSUME_NONNULL_BEGIN

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
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (void)logImplicitEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
             accessToken:(FBSDKAccessToken *)accessToken;

- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;
- (void)startObservingApplicationLifecycleNotifications;

@end

NS_ASSUME_NONNULL_END
