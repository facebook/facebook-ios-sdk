/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The error domain for all errors from LoginKit
/// Error codes from the SDK in the range 300-399 are reserved for login errors in this domain.
/// Error codes from the SDK in the range 1349100-1349199 are reserved for device login errors in this domain.
FOUNDATION_EXPORT NSErrorDomain const FBSDKLoginErrorDomain;

NS_ASSUME_NONNULL_END
