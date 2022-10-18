/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class EventDeactivationManager: _AppEventsParameterProcessing, _EventsProcessing {
  private struct DeactivatedEvent {
    let eventName: String
    let parameters: Set<String>
  }

  private enum Keys {
    static let event = "event"
    static let eventName = "_eventName"
    static let deprecatedParameter = "deprecated_param"
    static let isDeprecatedEvent = "is_deprecated_event"
  }

  private var isEventDeactivationEnabled = false
  private var deactivatedEvents = Set<String>()
  private var eventsWithDeactivatedParameters = [DeactivatedEvent]()

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    enableOnce()
  }

  private lazy var enableOnce: () -> Void = {
    guard let dependencies = try? getDependencies() else { return {} }

    if let restrictiveParams = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .restrictiveParams as? [String: [String: Any]] {
      updateDeactivatedEvents(restrictiveParams)
      isEventDeactivationEnabled = true
    }
    return {}
  }()

  func processEvents(_ events: NSMutableArray) {
    guard isEventDeactivationEnabled else { return }

    events.forEach { eventDictionary in
      guard let nested = eventDictionary as? [String: [String: Any]],
            let event = nested[Keys.event],
            let eventName = event[Keys.eventName] as? String
      else { return }

      if deactivatedEvents.contains(eventName) {
        events.remove(eventDictionary)
      }
    }
  }

  func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name
  ) -> [AppEvents.ParameterName: Any]? {
    guard isEventDeactivationEnabled,
          let parameters = parameters,
          !parameters.isEmpty,
          !eventsWithDeactivatedParameters.isEmpty
    else {
      return parameters
    }

    let params = NSMutableDictionary(dictionary: parameters)
    parameters.keys.forEach { appEventParameterName in
      eventsWithDeactivatedParameters.forEach { event in
        if event.eventName == eventName.rawValue,
           event.parameters.contains(appEventParameterName.rawValue) {
          params.removeObject(forKey: appEventParameterName)
        }
      }
    }
    return params.copy() as? [AppEvents.ParameterName: Any] ?? parameters
  }

  private func updateDeactivatedEvents(_ events: [String: [String: Any]]) {
    guard !events.isEmpty else { return }

    deactivatedEvents.removeAll()
    eventsWithDeactivatedParameters.removeAll()

    events.forEach { event in
      if event.value.keys.contains(Keys.isDeprecatedEvent) {
        deactivatedEvents.insert(event.key)
      }

      if let deprecatedParameters = event.value[Keys.deprecatedParameter] as? [String] {
        let deactivatedEvent = DeactivatedEvent(
          eventName: event.key,
          parameters: Set(deprecatedParameters)
        )
        eventsWithDeactivatedParameters.append(deactivatedEvent)
      }
    }
  }
}

extension EventDeactivationManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
