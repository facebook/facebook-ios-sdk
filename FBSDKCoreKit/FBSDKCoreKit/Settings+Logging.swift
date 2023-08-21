/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

extension Settings {
  /**
   Internal method exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public func recordInstall() {
    guard
      let dataStore = try? getDependencies().dataStore,
      dataStore.fb_object(forKey: PersistenceKey.installTimestamp.rawValue) == nil
    else { return }

    dataStore.fb_setObject(Date(), forKey: PersistenceKey.installTimestamp.rawValue)
  }

  func recordSetAdvertiserTrackingEnabled() {
    // swiftformat:disable:next redundantSelf
    self.dataStore?.fb_setObject(Date(), forKey: PersistenceKey.setAdvertiserTrackingEnabledTimestamp.rawValue)
  }

  /**
   Internal method exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public func logWarnings() {
    // Log warnings for App Event Flags
    // swiftformat:disable:next redundantSelf
    if self.infoDictionaryProvider?
      .fb_object(forInfoDictionaryKey: PersistenceKey.isAutoLogAppEventsEnabled.rawValue) == nil {
      print(AppEventFlagWarningMessages.isAutoLogAppEventsEnabledNotSet)
    }

    // swiftformat:disable:next redundantSelf
    if self.infoDictionaryProvider?
      .fb_object(forInfoDictionaryKey: PersistenceKey.isAdvertiserIDCollectionEnabled.rawValue) == nil {
      print(AppEventFlagWarningMessages.isAdvertiserIDCollectionEnabledNotSet)
    }

    if !(_isAdvertiserIDCollectionEnabled ?? false) {
      print(AppEventFlagWarningMessages.isAdvertiserIDCollectionEnabledFalse)
    }
  }

  /**
   Internal method exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public func logIfSDKSettingsChanged() {
    guard let dependencies = try? getDependencies() else { return }

    var bitmask = 0

    // Starting at 1 to maintain the meaning of the bits since the `autoInit` flag was removed.
    var bit = 1

    bitmask |= (isAutoLogAppEventsEnabled ? 1 : 0) << bit
    bit += 1

    bitmask |= (isAdvertiserIDCollectionEnabled ? 1 : 0) << bit
    bit += 1

    let previousBitmask = dependencies.dataStore.fb_integer(forKey: PersistenceKey.bitmask.rawValue)
    guard bitmask != previousBitmask else { return }

    dependencies.dataStore.fb_setInteger(bitmask, forKey: PersistenceKey.bitmask.rawValue)

    var initialBitmask = 0
    var usageBitmask = 0
    let bits: [(key: PersistenceKey, defaultValue: Bool)] = [
      (key: .isAutoLogAppEventsEnabled, defaultValue: true),
      (key: .isAdvertiserIDCollectionEnabled, defaultValue: true),
    ]

    bit = 0
    bits.forEach { key, defaultValue in
      let potentialFlag = (dependencies.infoDictionaryProvider.fb_object(forInfoDictionaryKey: key.rawValue) as? Bool)

      initialBitmask |= ((potentialFlag ?? defaultValue) ? 1 : 0) << bit
      usageBitmask |= ((potentialFlag != nil) ? 1 : 0) << bit

      bit += 1
    }

    dependencies.eventLogger.logInternalEvent(
      .sdkSettingsChanged,
      parameters: [
        .sdkSettingsUsageBitmask: usageBitmask,
        .sdkSettingsInitialBitmask: initialBitmask,
        .sdkSettingsPreviousBitmask: previousBitmask,
        .sdkSettingsCurrentBitmask: bitmask,
      ],
      isImplicitlyLogged: true
    )
  }

  private enum AppEventFlagWarningMessages {
    static let isAutoLogAppEventsEnabledNotSet = """
      <Warning>: Please set a value for FacebookAutoLogAppEventsEnabled. Set the flag to TRUE if you want \
      to collect app install, app launch and in-app purchase events automatically. To request user consent \
      before collecting data, set the flag value to FALSE, then change to TRUE once user consent is received. \
      Learn more: https://developers.facebook.com/docs/app-events/getting-started-app-events-ios#disable-auto-events.
      """
    static let isAdvertiserIDCollectionEnabledNotSet = """
      <Warning>: You haven't set a value for FacebookAdvertiserIDCollectionEnabled. Set the flag to TRUE if \
      you want to collect Advertiser ID for better advertising and analytics results.
      """
    static let isAdvertiserIDCollectionEnabledFalse = """
      <Warning>: The value for FacebookAdvertiserIDCollectionEnabled is currently set to FALSE so you're sending app \
      events without collecting Advertiser ID. This can affect the quality of your advertising and analytics results.
      """
  }
}

// swiftformat:disable:next extensionAccessControl
fileprivate extension AppEvents.ParameterName {
  static let sdkSettingsUsageBitmask = Self("usage")
  static let sdkSettingsInitialBitmask = Self("initial")
  static let sdkSettingsPreviousBitmask = Self("previous")
  static let sdkSettingsCurrentBitmask = Self("current")
}
