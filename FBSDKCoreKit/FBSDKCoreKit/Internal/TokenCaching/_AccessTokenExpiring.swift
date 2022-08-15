/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// This is an empty protocol used to mark an abstraction for a type that
// must be retained in order to continue monitoring for the expiration of
// access tokens.

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(_FBSDKAccessTokenExpiring)
public protocol _AccessTokenExpiring {}
