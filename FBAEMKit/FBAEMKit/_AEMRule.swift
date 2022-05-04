/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMRule)
public final class _AEMRule: NSObject, NSCopying, NSSecureCoding {
  public let conversionValue: Int
  public let priority: Int
  public let events: [_AEMEvent]

  private enum Keys {
    static let conversionValueKey: String = "conversion_value"
    static let priorityKey: String = "priority"
    static let eventsKey: String = "events"
  }

  @objc(initWithJSON:)
  public init?(json dict: [String: Any]) {
    let conversionValue = dict[Keys.conversionValueKey] as? NSNumber
    let priority = dict[Keys.priorityKey] as? NSNumber
    let events = _AEMRule.parse(events: dict[Keys.eventsKey] as? [[String: Any]] ?? []) ?? []

    guard let conversionValue = conversionValue,
          let priority = priority,
          !events.isEmpty
    else {
      return nil
    }

    self.conversionValue = conversionValue.intValue
    self.priority = priority.intValue
    self.events = events

    super.init()
  }

  /// Check if event contains target event with name
  /// - Parameter event: Event name to check for
  /// - Returns: Boolean
  @objc(containsEvent:)
  public func containsEvent(_ event: String) -> Bool {
    events.contains { $0.eventName == event }
  }

  /// Check if recorded events and values match `events`
  /// - Parameters:
  ///   - recordedEvents: Recorded events to check
  ///   - recordedValues: Recorded values to check
  /// - Returns: Boolean
  @objc(isMatchedWithRecordedEvents:recordedValues:)
  public func isMatched(
    withRecordedEvents recordedEvents: Set<String>?,
    recordedValues: [String: [String: Any]]?
  ) -> Bool {
    guard let recordedEvents = recordedEvents else {
      return false
    }

    for event in events {
      // Check if event name matches
      if !recordedEvents.contains(event.eventName) {
        return false
      }
      // Check if event value matches when values is not nil
      if let values = event.values,
         !values.isEmpty {
        let recordedEventValues = recordedValues?[event.eventName] as? [String: Double]
        if !isMatched(values: values, recordedEventValues: recordedEventValues) {
          return false
        }
      }
    }

    return true
  }

  /// Attempts value matching for event values
  /// - Parameters:
  ///   - values: Event values
  ///   - recordedEventValues: Recorded event values to check (nullable)
  /// - Returns: Boolean
  private func isMatched(values: [String: Double], recordedEventValues: [String: Double]?) -> Bool {
    for (currency, valueInMapping) in values {
      let value = recordedEventValues?[currency] ?? 0
      if value >= valueInMapping {
        return true
      }
    }

    return false
  }

  /// Parse json dictionary to collection of `_AEMEvent`
  /// - Parameter events: Collection of dictionaries to parse
  /// - Returns: Collection of `_AEMEvent` objects
  private static func parse(
    events: [[String: Any]]
  ) -> [_AEMEvent]? {
    guard !events.isEmpty else {
      return nil
    }

    return events.compactMap(_AEMEvent.init(dict:))
  }

  // MARK: - NSCoding

  public static var supportsSecureCoding: Bool {
    true
  }

  public init?(coder: NSCoder) {
    let conversionValue = coder.decodeInteger(forKey: Keys.conversionValueKey)
    let priority = coder.decodeInteger(forKey: Keys.priorityKey)
    let events: [_AEMEvent] = coder.decodeObject(
      of: [NSArray.classForCoder(), _AEMEvent.classForCoder()],
      forKey: Keys.eventsKey
    ) as? [_AEMEvent] ?? []

    self.conversionValue = conversionValue
    self.priority = priority
    self.events = events
  }

  public func encode(with coder: NSCoder) {
    coder.encode(conversionValue, forKey: Keys.conversionValueKey)
    coder.encode(priority, forKey: Keys.priorityKey)
    coder.encode(events, forKey: Keys.eventsKey)
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    self
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let rule = object as?_AEMRule else {
      return false
    }

    if self === rule {
      return true
    }

    return conversionValue == rule.conversionValue
    && priority == rule.priority
    && events == rule.events
  }
}

#endif
