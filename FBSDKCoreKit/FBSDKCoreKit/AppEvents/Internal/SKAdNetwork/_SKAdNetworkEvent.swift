/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKSKAdNetworkEvent)
public final class _SKAdNetworkEvent: NSObject {
  public let eventName: String?
  public var values: [String: Double]?

  private enum Keys {
    static let eventName = "event_name"
    static let values = "values"
    static let currency = "currency"
    static let amount = "amount"
  }

  @objc(initWithJSON:)
  public init?(json: [String: Any]) {

    guard let eventName = json[Keys.eventName] as? String else {
      return nil
    }
    self.eventName = eventName

    guard let valueEntries = json[Keys.values] as? [[String: Any]] else {
      return
    }
    var values = [String: Double]()
    for valueEntry in valueEntries {

      guard
        let currency = valueEntry[Keys.currency] as? String,
        let amount = valueEntry[Keys.amount] as? Double
      else {
        return nil
      }

      values[currency.uppercased()] = amount
    }

    self.values = values
  }
}

#endif
