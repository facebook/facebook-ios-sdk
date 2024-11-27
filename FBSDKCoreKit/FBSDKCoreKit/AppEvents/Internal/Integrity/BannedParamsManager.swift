/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class BannedParamsManager: NSObject, MACARuleMatching {
  private var isEnabled = false
  private var blockedParamsConfig = Set<String>()
  private static let stdParamsBlockedKey = "standard_params_blocked"
  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    if isEnabled {
      return
    }
    guard let dependencies = try? getDependencies() else {
      return
    }
    configureBlockedParams(dependencies: dependencies)
    if !blockedParamsConfig.isEmpty {
      isEnabled = true
    }
  }

  func processParameters(_ params: NSDictionary?, event: String?) -> NSDictionary? {
    if !isEnabled {
      return params
    }
    guard let params = params else { return params }

    let updatedParams = params.mutableCopy() as? NSMutableDictionary
    for param in blockedParamsConfig {
      updatedParams?.removeObject(forKey: param)
    }
    return updatedParams
  }

  private func configureBlockedParams(dependencies: ObjectDependencies) {
    guard let blockedParams = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?[BannedParamsManager.stdParamsBlockedKey] as? [String]
    else { return }
    blockedParamsConfig.formUnion(blockedParams)
  }
}

extension BannedParamsManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}

// MARK: - Testing

#if DEBUG
extension BannedParamsManager {
  func getIsEnabled() -> Bool {
    isEnabled
  }

  func getBlockedParams() -> Set<String> {
    blockedParamsConfig
  }
}
#endif
