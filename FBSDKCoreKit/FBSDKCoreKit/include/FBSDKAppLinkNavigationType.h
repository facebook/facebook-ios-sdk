/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

/// The result of calling navigate on a FBSDKAppLinkNavigation
typedef NS_ENUM(NSInteger, FBSDKAppLinkNavigationType) {
  /// Indicates that the navigation failed and no app was opened
  FBSDKAppLinkNavigationTypeFailure,
  /// Indicates that the navigation succeeded by opening the URL in the browser
  FBSDKAppLinkNavigationTypeBrowser,
  /// Indicates that the navigation succeeded by opening the URL in an app on the device
  FBSDKAppLinkNavigationTypeApp,
} NS_SWIFT_NAME(AppLinkNavigationType);

#endif
