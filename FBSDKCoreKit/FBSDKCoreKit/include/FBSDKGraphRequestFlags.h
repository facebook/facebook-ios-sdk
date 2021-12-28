/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Flags that indicate how a graph request should be treated in various scenarios
 */
typedef NS_OPTIONS(NSUInteger, FBSDKGraphRequestFlags) {
  FBSDKGraphRequestFlagNone = 0,
  // indicates this request should not use a client token as its token parameter
  FBSDKGraphRequestFlagSkipClientToken = 1 << 1,
  // indicates this request should not close the session if its response is an oauth error
  FBSDKGraphRequestFlagDoNotInvalidateTokenOnError = 1 << 2,
  // indicates this request should not perform error recovery
  FBSDKGraphRequestFlagDisableErrorRecovery = 1 << 3,
} NS_SWIFT_NAME(GraphRequestFlags);

NS_ASSUME_NONNULL_END
