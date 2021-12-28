/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

/// This is an empty protocol used to mark an abstraction for a type that
/// must be retained in order to continue monitoring for the expiration of
/// access tokens.
NS_SWIFT_NAME(AccessTokenExpiring)
@protocol FBSDKAccessTokenExpiring

@end

NS_ASSUME_NONNULL_END
