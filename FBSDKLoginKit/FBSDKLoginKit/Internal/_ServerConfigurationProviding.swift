/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(_FBSDKServerConfigurationProviding)
public protocol _ServerConfigurationProviding {
  @objc(loadServerConfigurationWithCompletionBlock:)
  func loadServerConfiguration(completion: LoginTooltipBlock?)
}
