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
    // TODO: Implement this
    return nil
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
