/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKBlocklistEventsManager)
final class BlocklistEventsManager: NSObject, _EventsProcessing {

  private var isEnabled = false
  private var blocklistedEventNames = Set<String>()
  private static let blocklistEventsKey = "blocklist_events"
  private static let eventKey = "event"

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    guard let dependencies = try? getDependencies() else {
      return
    }
    if let blocklistedEvents = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?[BlocklistEventsManager.blocklistEventsKey] as? [String] {
      if !blocklistedEvents.isEmpty {
        blocklistedEventNames = Set(blocklistedEvents)
        isEnabled = true
      }
    }
  }

  func processEvents(_ events: NSMutableArray) {
    guard isEnabled else { return }

    var filteredEvents = [Any]()
    events.forEach { eventDictionary in
      guard let eventDictionaryTyped = eventDictionary as? [String: Any],
            let event = eventDictionaryTyped[BlocklistEventsManager.eventKey] as? [NSString: Any],
            let eventName = (event as [String: Any])[AppEvents.ParameterName.eventName.rawValue] as? String
      else { return }
      if !blocklistedEventNames.contains(eventName) {
        filteredEvents.append(eventDictionary)
      }
    }
    events.removeAllObjects()
    events.addObjects(from: filteredEvents)
  }
}

extension BlocklistEventsManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
