/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 NS_ENUM(NSUInteger, FBSDKGameRequestFilters)
  Filter for who can be displayed in the multi-friend selector.
 */
typedef NS_ENUM(NSUInteger, FBSDKGameRequestFilter) {
  /** No filter, all friends can be displayed. */
  FBSDKGameRequestFilterNone = 0,
  /** Friends using the app can be displayed. */
  FBSDKGameRequestFilterAppUsers,
  /** Friends not using the app can be displayed. */
  FBSDKGameRequestFilterAppNonUsers,
  /**All friends can be displayed if FB app is installed.*/
  FBSDKGameRequestFilterEverybody,
} NS_SWIFT_NAME(GameRequestFilter);

NS_ASSUME_NONNULL_END
