/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** The name of the notification posted by FBSDKMeasurementEvent */
FOUNDATION_EXPORT NSNotificationName const FBSDKMeasurementEventNotification
NS_SWIFT_NAME(MeasurementEvent);

/** Defines keys in the userInfo object for the notification named FBSDKMeasurementEventNotificationName */
/** The string field for the name of the event */
FOUNDATION_EXPORT NSString *const FBSDKMeasurementEventNameKey
NS_SWIFT_NAME(MeasurementEventNameKey);
/** The dictionary field for the arguments of the event */
FOUNDATION_EXPORT NSString *const FBSDKMeasurementEventArgsKey
NS_SWIFT_NAME(MeasurementEventArgsKey);

/** Events raised by FBSDKMeasurementEvent for Applink */
/**
 The name of the event posted when [FBSDKURL URLWithURL:] is called successfully. This represents the successful parsing of an app link URL.
 */
FOUNDATION_EXPORT NSString *const FBSDKAppLinkParseEventName
NS_SWIFT_NAME(AppLinkParseEventName);

/**
 The name of the event posted when [FBSDKURL URLWithInboundURL:] is called successfully.
 This represents parsing an inbound app link URL from a different application
 */
FOUNDATION_EXPORT NSString *const FBSDKAppLinkNavigateInEventName
NS_SWIFT_NAME(AppLinkNavigateInEventName);

/** The event raised when the user navigates from your app to other apps */
FOUNDATION_EXPORT NSString *const FBSDKAppLinkNavigateOutEventName
NS_SWIFT_NAME(AppLinkNavigateOutEventName);

/**
 The event raised when the user navigates out from your app and back to the referrer app.
 e.g when the user leaves your app after tapping the back-to-referrer navigation bar
 */
FOUNDATION_EXPORT NSString *const FBSDKAppLinkNavigateBackToReferrerEventName
NS_SWIFT_NAME(AppLinkNavigateBackToReferrerEventName);

NS_ASSUME_NONNULL_END

#endif
