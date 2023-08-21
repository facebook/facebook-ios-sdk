/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension Settings {
  struct PersistedStringProperty {
    let persistenceKey: Settings.PersistenceKey
    let backingKeyPath: ReferenceWritableKeyPath<Settings, String?>

    static let appURLSchemeSuffix = Self(
      persistenceKey: .urlSchemeSuffix,
      backingKeyPath: \._appURLSchemeSuffix
    )

    static let clientToken = Self(
      persistenceKey: .clientToken,
      backingKeyPath: \._clientToken
    )

    static let displayName = Self(
      persistenceKey: .displayName,
      backingKeyPath: \._displayName
    )

    static let facebookDomainPart = Self(
      persistenceKey: .domainPart,
      backingKeyPath: \._facebookDomainPart
    )
  }

  func getPersistedStringProperty(_ property: PersistedStringProperty) -> String? {
    if let value = self[keyPath: property.backingKeyPath] {
      return value
    }

    // swiftformat:disable:next redundantSelf
    guard let infoDictionaryProvider = self.infoDictionaryProvider else { return nil }

    let value = infoDictionaryProvider.fb_object(forInfoDictionaryKey: property.persistenceKey.rawValue) as? String
    self[keyPath: property.backingKeyPath] = value
    return value
  }

  func setPersistedStringProperty(_ property: PersistedStringProperty, to value: String?) {
    validateConfiguration()
    self[keyPath: property.backingKeyPath] = value
    logIfSDKSettingsChanged()
  }
}

extension Settings {
  struct PersistedBooleanValue {
    let persistenceKey: Settings.PersistenceKey
    let backingKeyPath: ReferenceWritableKeyPath<Settings, Bool?> // swiftlint:disable:this discouraged_optional_boolean
    let defaultValue: Bool

    static let isAutoLogAppEventsEnabled = Self(
      persistenceKey: .isAutoLogAppEventsEnabled,
      backingKeyPath: \._isAutoLogAppEventsEnabled,
      defaultValue: true
    )

    static let isAdvertiserIDCollectionEnabled = Self(
      persistenceKey: .isAdvertiserIDCollectionEnabled,
      backingKeyPath: \._isAdvertiserIDCollectionEnabled,
      defaultValue: true
    )

    static let isCodelessDebugLogEnabled = Self(
      persistenceKey: .isCodelessDebugLogEnabled,
      backingKeyPath: \._isCodelessDebugLogEnabled,
      defaultValue: false
    )
  }

  func getPersistedBooleanProperty(_ property: PersistedBooleanValue) -> Bool {
    if let value = self[keyPath: property.backingKeyPath] {
      return value
    }

    guard let dependencies = try? getDependencies() else { return property.defaultValue }

    let numberValue = dependencies.dataStore.fb_object(forKey: property.persistenceKey.rawValue) as? NSNumber
      // swiftlint:disable:next line_length
      ?? dependencies.infoDictionaryProvider.fb_object(forInfoDictionaryKey: property.persistenceKey.rawValue) as? NSNumber

    let value = numberValue?.boolValue ?? property.defaultValue
    self[keyPath: property.backingKeyPath] = value
    return value
  }

  func setPersistedBooleanProperty(_ property: PersistedBooleanValue, to value: Bool) {
    validateConfiguration()
    // swiftformat:disable:next redundantSelf
    self.dataStore?.fb_setObject(value, forKey: property.persistenceKey.rawValue)
    logIfSDKSettingsChanged()
  }
}
