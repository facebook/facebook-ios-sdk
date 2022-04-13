/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

@class FBSDKLoginManagerLoginResult;

/**
 Describes the call back to the FBSDKLoginManager
 @param result the result of the authorization
 @param error the authorization error, if any.
 */
typedef void (^ FBSDKLoginManagerLoginResultBlock)(FBSDKLoginManagerLoginResult *_Nullable result,
  NSError *_Nullable error)
NS_SWIFT_NAME(LoginManagerLoginResultBlock);

#endif
