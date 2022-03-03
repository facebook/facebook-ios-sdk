/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)
/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMEvent)
public final class AEMEvent: NSObject, NSCopying, NSSecureCoding {
  enum CodingKeys: String, CodingKey {
    case eventName = "event_name"
    case values
    case currency
    case amount
  }

  public private(set) var eventName: String
  public private(set) var values: [String: Int]?

  @objc(initWithJSON:)
  public init?(dict: [String: Any]?) {
    guard let dict = dict else { return nil }

    // Event name is a required field
    guard let eventName = dict[CodingKeys.eventName.rawValue] as? String else {
      return nil
    }
    self.eventName = eventName

    // Values is an optional field, so don't return nil
    guard let valueEntries = dict[CodingKeys.values.rawValue] as? [[String: Any]] else { return }

    if !valueEntries.isEmpty {
      var valuesDict: [String: Int] = [:]

      for valueEntry in valueEntries {
        guard let currency = valueEntry[CodingKeys.currency.rawValue] as? String,
              let amount = valueEntry[CodingKeys.amount.rawValue] as? Int,
              !currency.isEmpty else {
          return nil
        }
        valuesDict[currency.uppercased()] = amount
      }

      values = valuesDict
    }
  }

  private init(eventName: String, values: [String: Int]?) {
    self.eventName = eventName
    self.values = values
  }

  // MARK: NSSecureCoding

  public static var supportsSecureCoding: Bool {
    true
  }

  public convenience init?(coder: NSCoder) {
    let decodedEventName = coder.decodeObject(of: NSString.self, forKey: CodingKeys.eventName.rawValue) as String? ?? ""
    let decodedValues = coder.decodeObject(
      of: [NSDictionary.self, NSNumber.self, NSString.self],
      forKey: CodingKeys.values.rawValue
    ) as? [String: Int]
    self.init(eventName: decodedEventName, values: decodedValues)
  }

  public func encode(with coder: NSCoder) {
    coder.encode(eventName, forKey: CodingKeys.eventName.rawValue)
    if values != nil {
      coder.encode(values, forKey: CodingKeys.values.rawValue)
    }
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    self
  }
}

#endif
