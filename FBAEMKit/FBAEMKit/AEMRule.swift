/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import Foundation

final class AEMRule: NSObject, NSSecureCoding {
  let conversionValue: Int
  let priority: Int
  let events: [AEMEvent]

  private enum Keys {
    static let conversionValueKey = "conversion_value"
    static let priorityKey = "priority"
    static let eventsKey = "events"
  }

  init?(json dict: [String: Any]) {
    let conversionValue = dict[Keys.conversionValueKey] as? NSNumber
    let priority = dict[Keys.priorityKey] as? NSNumber
    let events = AEMRule.parse(events: dict[Keys.eventsKey] as? [[String: Any]] ?? []) ?? []

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
  func containsEvent(_ event: String) -> Bool {
    events.contains { $0.eventName == event }
  }

  /// Check if recorded events and values match `events`
  /// - Parameters:
  ///   - recordedEvents: Recorded events to check
  ///   - recordedValues: Recorded values to check
  /// - Returns: Boolean
  func isMatched(
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

  /// Parse json dictionary to collection of `AEMEvent`
  /// - Parameter events: Collection of dictionaries to parse
  /// - Returns: Collection of `AEMEvent` objects
  private static func parse(
    events: [[String: Any]]
  ) -> [AEMEvent]? {
    guard !events.isEmpty else {
      return nil
    }

    return events.compactMap(AEMEvent.init(dict:))
  }

  // MARK: - NSCoding

  static var supportsSecureCoding: Bool {
    true
  }

  init?(coder: NSCoder) {
    let conversionValue = coder.decodeInteger(forKey: Keys.conversionValueKey)
    let priority = coder.decodeInteger(forKey: Keys.priorityKey)
    let events: [AEMEvent] = coder.decodeObject(
      of: [NSArray.classForCoder(), AEMEvent.classForCoder()],
      forKey: Keys.eventsKey
    ) as? [AEMEvent] ?? []

    self.conversionValue = conversionValue
    self.priority = priority
    self.events = events
  }

  func encode(with coder: NSCoder) {
    coder.encode(conversionValue, forKey: Keys.conversionValueKey)
    coder.encode(priority, forKey: Keys.priorityKey)
    coder.encode(events, forKey: Keys.eventsKey)
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let rule = object as? AEMRule else {
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
