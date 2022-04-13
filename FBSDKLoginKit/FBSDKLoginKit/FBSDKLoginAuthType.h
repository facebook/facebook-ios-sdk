/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#if !TARGET_OS_TV

/// typedef for FBSDKLoginAuthType
/// See: https://developers.facebook.com/docs/reference/javascript/FB.login/v10.0#options
typedef NSString *const FBSDKLoginAuthType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(LoginAuthType);

/// Rerequest
FOUNDATION_EXPORT FBSDKLoginAuthType FBSDKLoginAuthTypeRerequest;

/// Reauthorize
FOUNDATION_EXPORT FBSDKLoginAuthType FBSDKLoginAuthTypeReauthorize;

#endif
