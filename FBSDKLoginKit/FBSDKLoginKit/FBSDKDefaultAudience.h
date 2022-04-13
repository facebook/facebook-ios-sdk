/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

/**
 FBSDKDefaultAudience enum

  Passed to openURL to indicate which default audience to use for sessions that post data to Facebook.

 Certain operations such as publishing a status or publishing a photo require an audience. When the user
 grants an application permission to perform a publish operation, a default audience is selected as the
 publication ceiling for the application. This enumerated value allows the application to select which
 audience to ask the user to grant publish permission for.
 */
typedef NS_ENUM(NSUInteger, FBSDKDefaultAudience) {
  /// Indicates that the user's friends are able to see posts made by the application
  FBSDKDefaultAudienceFriends = 0,
  /// Indicates that only the user is able to see posts made by the application
  FBSDKDefaultAudienceOnlyMe,
  /// Indicates that all Facebook users are able to see posts made by the application
  FBSDKDefaultAudienceEveryone,
} NS_SWIFT_NAME(DefaultAudience);

NS_ASSUME_NONNULL_END

#endif
