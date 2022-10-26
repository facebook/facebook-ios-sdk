/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class AEMEvent: NSObject, NSSecureCoding {
  enum CodingKeys: String, CodingKey {
    case eventName = "event_name"
    case values
    case currency
    case amount
  }

  private(set) var eventName: String
  private(set) var values: [String: Double]?

  init?(dict: [String: Any]?) {
    guard let dict = dict else { return nil }

    // Event name is a required field
    guard let eventName = dict[CodingKeys.eventName.rawValue] as? String else {
      return nil
    }
    self.eventName = eventName

    // Values is an optional field, so don't return nil
    guard let valueEntries = dict[CodingKeys.values.rawValue] as? [[String: Any]] else { return }

    if !valueEntries.isEmpty {
      var valuesDict: [String: Double] = [:]

      for valueEntry in valueEntries {
        guard let currency = valueEntry[CodingKeys.currency.rawValue] as? String,
              let amount = valueEntry[CodingKeys.amount.rawValue] as? Double,
              !currency.isEmpty else {
          return nil
        }
        valuesDict[currency.uppercased()] = amount
      }

      values = valuesDict
    }
  }

  private init(eventName: String, values: [String: Double]?) {
    self.eventName = eventName
    self.values = values
  }

  // MARK: NSSecureCoding

  static var supportsSecureCoding: Bool {
    true
  }

  convenience init?(coder: NSCoder) {
    let decodedEventName = coder.decodeObject(of: NSString.self, forKey: CodingKeys.eventName.rawValue) as String? ?? ""
    let decodedValues = coder.decodeObject(
      of: [NSDictionary.self, NSNumber.self, NSString.self],
      forKey: CodingKeys.values.rawValue
    ) as? [String: Double]
    self.init(eventName: decodedEventName, values: decodedValues)
  }

  func encode(with coder: NSCoder) {
    coder.encode(eventName, forKey: CodingKeys.eventName.rawValue)
    if values != nil {
      coder.encode(values, forKey: CodingKeys.values.rawValue)
    }
  }

  // MARK: - NSObject

  override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? AEMEvent else { return false }

    return eventName == other.eventName
      && values == other.values
  }
}
