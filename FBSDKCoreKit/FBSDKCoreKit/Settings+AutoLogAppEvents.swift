/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

extension Settings {
  enum AutoLogAppEventServerFlags: String {
    case DEFAUT = "auto_log_app_events_default"
    case ENABLE = "auto_log_app_events_enabled"
  }

  /// Auto logging requires both the client-side flag and the server-side control to be on.
  func checkAutoLogAppEventsEnabled() -> Bool {
    guard let dependencies = try? getDependencies() else {
      return true
    }
    guard let migratedAutoLogValues = dependencies
      .serverConfigurationProvider.cachedServerConfiguration().migratedAutoLogValues else {
      return isAutoLogAppEventsEnabledLocally
    }
    let isEnabledOnClient = checkClientSideConfiguration(dependencies) ?? true
    return isEnabledOnClient && checkServerSideConfiguration(migratedAutoLogValues)
  }

  private func checkServerSideConfiguration(_ migratedAutoLogValues: [String: Any]) -> Bool {
    if let serverEnabled = migratedAutoLogValues[AutoLogAppEventServerFlags.ENABLE.rawValue] as? NSNumber {
      return serverEnabled.boolValue
    }
    if let serverDefault = migratedAutoLogValues[AutoLogAppEventServerFlags.DEFAUT.rawValue] as? NSNumber {
      return serverDefault.boolValue
    }
    return true
  }

  // swiftlint:disable:next discouraged_optional_boolean
  private func checkClientSideConfiguration(_ dependencies: ObjectDependencies) -> Bool? {
    if let isAutoLogAppEventsEnabledInUserDefault = checkUserDefault() {
      return isAutoLogAppEventsEnabledInUserDefault
    }
    if let isAutoLogAppEventsEnabledInPlist = checkInfoPlist(dependencies) {
      return isAutoLogAppEventsEnabledInPlist
    }
    return nil
  }

  // swiftlint:disable:next discouraged_optional_boolean
  private func checkInfoPlist(_ dependencies: ObjectDependencies) -> Bool? {
    if let infoPlistValue = dependencies.infoDictionaryProvider
      .fb_object(forInfoDictionaryKey: PersistenceKey.isAutoLogAppEventsEnabledLocally.rawValue) as? NSNumber {
      return infoPlistValue.boolValue
    }
    return nil
  }

  // swiftlint:disable:next discouraged_optional_boolean
  private func checkUserDefault() -> Bool? {
    // swiftformat:disable:this redundantSelf
    if let userDefaultValue = self.dataStore?
      .fb_object(forKey: Settings.PersistenceKey.isAutoLogAppEventsEnabledLocally.rawValue) as? NSNumber {
      return userDefaultValue.boolValue
    }
    return nil
  }
}
