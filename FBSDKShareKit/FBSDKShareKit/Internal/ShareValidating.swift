/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol ShareValidating {
  static func validateRequiredValue(_ value: Any, named name: String) throws

  static func validateArgument<Argument>(
    _ value: Argument,
    named name: String,
    in possibleValues: Set<Argument>
  ) throws

  static func validateArray(
    _ array: [Any],
    minCount: Int,
    maxCount: Int,
    named name: String
  ) throws

  static func validateNetworkURL(_ url: URL, named name: String) throws

  static func validateShareContent(
    _ shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions
  ) throws
}
