/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKRedactedEventsManager)
final class RedactedEventsManager: NSObject, _EventsProcessing {

  private var isEnabled = false
  private var redactedEventsConfig = [String: Set<String>]()
  private static let redactedEventsKey = "redacted_events"
  private static let eventKey = "event"
  private static let isImplicitKey = "isImplicit"

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    guard let dependencies = try? getDependencies() else {
      return
    }
    guard let redactedEvents = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?[RedactedEventsManager.redactedEventsKey] as? [[String: Any]]
    else { return }
    redactedEventsConfig = getRedactedEventsConfig(redactedEvents: redactedEvents)
    if !redactedEventsConfig.isEmpty {
      isEnabled = true
    }
  }

  func processEvents(_ events: NSMutableArray) {
    guard isEnabled else { return }

    var filteredEvents = [Any]()
    events.forEach { eventDictionary in
      guard let eventDictionaryTyped = eventDictionary as? [String: Any],
            var event = eventDictionaryTyped[RedactedEventsManager.eventKey] as? [NSString: Any],
            let eventName = (event as [String: Any])[AppEvents.ParameterName.eventName.rawValue] as? String
      else { return }
      if let redactionString = getRedactionStringFor(eventName: eventName) {
        event[AppEvents.ParameterName.eventName.rawValue as NSString] = redactionString
        let redactedEvent = NSMutableDictionary()
        redactedEvent[RedactedEventsManager.eventKey] = NSMutableDictionary(dictionary: event)
        redactedEvent[RedactedEventsManager.isImplicitKey] = eventDictionaryTyped[RedactedEventsManager.isImplicitKey]
        filteredEvents.append(redactedEvent)
      } else {
        filteredEvents.append(eventDictionary)
      }
    }
    events.removeAllObjects()
    events.addObjects(from: filteredEvents)
  }

  private func getRedactedEventsConfig(redactedEvents: [[String: Any]]) -> [String: Set<String>] {
    var config = [String: Set<String>]()
    for redactedEventDict in redactedEvents {
      if let key = redactedEventDict["key"] as? String,
         let value = redactedEventDict["value"] as? [String] {
        if !config.keys.contains(key) {
          config[key] = Set(value)
        } else {
          config[key] = config[key]?.union(Set(value))
        }
      }
    }
    return config
  }

  private func getRedactionStringFor(eventName: String) -> String? {
    guard isEnabled else { return nil }

    for redactionString in redactedEventsConfig.keys {
      if let redactedEvents = redactedEventsConfig[redactionString],
         redactedEvents.contains(eventName) {
        return redactionString
      }
    }
    return nil
  }
}

extension RedactedEventsManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
