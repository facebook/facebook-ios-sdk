/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class SensitiveParamsManager: NSObject, _AppEventsParameterProcessing {

  private var isEnabled = false
  private var sensitiveParamsConfig = [String: Set<String>]()
  private var defaultSensitiveParams = Set<String>()
  private static let sensitiveParamsKey = "sensitive_params"
  private static let defaultSensitiveParamsKey = "_MTSDK_Default_"
  private static let filteredSensitiveParamsKey = AppEvents.ParameterName(rawValue: "_filteredKey")

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    guard let dependencies = try? getDependencies() else {
      return
    }
    guard let sensitiveParams = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?[SensitiveParamsManager.sensitiveParamsKey] as? [[String: Any]]
    else { return }
    configureSensitiveParams(sensitiveParams: sensitiveParams)
    if !sensitiveParamsConfig.isEmpty || !defaultSensitiveParams.isEmpty {
      isEnabled = true
    }
  }

  func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name?
  ) -> [AppEvents.ParameterName: Any]? {
    guard isEnabled,
          var parameters,
          !parameters.isEmpty
    else {
      return parameters
    }
    var filteredSensitiveParams = filterSensitiveParams(
      parameters: &parameters,
      sensitiveParams: defaultSensitiveParams
    )
    if let eventName,
       sensitiveParamsConfig.keys.contains(eventName.rawValue),
       let sensitiveParams = sensitiveParamsConfig[eventName.rawValue] {
      let result = filterSensitiveParams(parameters: &parameters, sensitiveParams: sensitiveParams)
      filteredSensitiveParams = filteredSensitiveParams.union(result)
    }
    if !filteredSensitiveParams.isEmpty {
      parameters[SensitiveParamsManager.filteredSensitiveParamsKey] = Array(filteredSensitiveParams)
    }
    return parameters
  }

  private func filterSensitiveParams(
    parameters: inout [AppEvents.ParameterName: Any],
    sensitiveParams: Set<String>
  ) -> Set<String> {
    var filteredSensitiveParams = Set<String>()
    for sensitiveParam in sensitiveParams {
      let appEventSensitiveParamName = AppEvents.ParameterName(rawValue: sensitiveParam)
      if parameters.keys.contains(appEventSensitiveParamName) {
        parameters.removeValue(forKey: appEventSensitiveParamName)
        filteredSensitiveParams.insert(appEventSensitiveParamName.rawValue)
      }
    }
    return filteredSensitiveParams
  }

  private func configureSensitiveParams(sensitiveParams: [[String: Any]]) {
    for sensitiveParamDict in sensitiveParams {
      if let key = sensitiveParamDict["key"] as? String,
         let value = sensitiveParamDict["value"] as? [String] {
        let sensitiveParamSet = Set(value)
        if key == SensitiveParamsManager.defaultSensitiveParamsKey {
          defaultSensitiveParams = sensitiveParamSet
        } else if !sensitiveParamsConfig.keys.contains(key) {
          sensitiveParamsConfig[key] = sensitiveParamSet
        } else {
          sensitiveParamsConfig[key] = sensitiveParamsConfig[key]?.union(sensitiveParamSet)
        }
      }
    }
  }
}

extension SensitiveParamsManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}

// MARK: - Testing

#if DEBUG
extension SensitiveParamsManager {
  func getIsEnabled() -> Bool {
    isEnabled
  }

  func getSensitiveParamsConfig() -> [String: Set<String>] {
    sensitiveParamsConfig
  }

  func getDefaultSensitiveParams() -> Set<String> {
    defaultSensitiveParams
  }
}
#endif
