/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKProfileProviding)
public protocol ProfileProviding {
  @objc(currentProfile)
  static var current: Profile? { get set }

  static func fetchCachedProfile() -> Profile?
}
