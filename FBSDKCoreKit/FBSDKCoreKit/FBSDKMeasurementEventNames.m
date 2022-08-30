/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKMeasurementEventNames.h"

NSNotificationName const FBSDKMeasurementEventNotification = @"com.facebook.facebook-objc-sdk.measurement_event";
/// app Link Event raised by this FBSDKURL
NSString *const FBSDKAppLinkParseEventName = @"al_link_parse";
NSString *const FBSDKAppLinkNavigateInEventName = @"al_nav_in";

/// AppLink events raised in this class
NSString *const FBSDKAppLinkNavigateOutEventName = @"al_nav_out";
NSString *const FBSDKAppLinkNavigateBackToReferrerEventName = @"al_ref_back_out";

#endif
