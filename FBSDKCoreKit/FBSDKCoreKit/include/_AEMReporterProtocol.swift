/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKAEMReporter)
public protocol _AEMReporterProtocol {
  static func enable()

  @objc(recordAndUpdateEvent:currency:value:parameters:)
  static func recordAndUpdate(
    event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?
  )

  static func setConversionFilteringEnabled(_ isEnabled: Bool)

  static func setCatalogMatchingEnabled(_ isEnabled: Bool)

  static func setAdvertiserRuleMatchInServerEnabled(_ isEnabled: Bool)
}

extension AEMReporter: _AEMReporterProtocol {}
