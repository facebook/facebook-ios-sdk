/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AdSupport
import Foundation

@objcMembers
@objc(FBSDKSettings)
public final class Settings: NSObject, SettingsProtocol, SettingsLogging, _ClientTokenProviding {

  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies?

  /// The shared settings instance. Prefer this and the exposed instance methods over the type properties and methods.
  @objc(sharedSettings)
  public static let shared = Settings()

  /// The Facebook SDK version in use.
  public var sdkVersion: String { FBSDK_VERSION_STRING }

  /// The default Graph API version.
  public var defaultGraphAPIVersion: String { FBSDK_DEFAULT_GRAPH_API_VERSION }

  /**
   The quality of JPEG images sent to Facebook from the SDK expressed as a value from 0.0 to 1.0.

   The default value is 0.9.
   */
  @objc(JPEGCompressionQuality)
  public var jpegCompressionQuality: CGFloat {
    get { _jpegCompressionQuality }
    set {
      validateConfiguration()
      _jpegCompressionQuality = clampJPEGCompressionQuality(newValue)
      logIfSDKSettingsChanged()
    }
  }

  private static let defaultJPEGCompressionQuality: CGFloat = 0.9

  private lazy var _jpegCompressionQuality = clampJPEGCompressionQuality(
    self.infoDictionaryProvider?
      .fb_object(forInfoDictionaryKey: PersistenceKey.jpegCompressionQuality.rawValue) as? CGFloat
      ?? Self.defaultJPEGCompressionQuality
  )

  private func clampJPEGCompressionQuality(_ quality: CGFloat) -> CGFloat {
    quality.fb_clamped(to: 0.0 ... 1.0)
  }

  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable let_var_whitespace

  /**
   Controls the automatic logging of basic app events such as `activateApp` and `deactivateApp`.

   The default value is `true`.
   */
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isAutoLogAppEventsEnabled` instead.
      """
  )
  public var autoLogAppEventsEnabled: Bool {
    get { isAutoLogAppEventsEnabled }
    set { isAutoLogAppEventsEnabled = newValue }
  }

  /**
   Controls the automatic logging of basic app events such as `activateApp` and `deactivateApp`.

   The default value is `true`.
   */
  public var isAutoLogAppEventsEnabled: Bool {
    get { getPersistedBooleanProperty(.isAutoLogAppEventsEnabled) }
    set { setPersistedBooleanProperty(.isAutoLogAppEventsEnabled, to: newValue) }
  }

  // swiftlint:disable:next identifier_name discouraged_optional_boolean
  var _isAutoLogAppEventsEnabled: Bool?

  /**
   Controls the `fb_codeless_debug` logging event.

   The default value is `false`.
   */
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isCodelessDebugLogEnabled` instead.
      """
  )
  public var codelessDebugLogEnabled: Bool {
    get { isCodelessDebugLogEnabled }
    set { isCodelessDebugLogEnabled = newValue }
  }

  /**
   Controls the `fb_codeless_debug` logging event.

   The default value is `false`.
   */
  public var isCodelessDebugLogEnabled: Bool {
    get { getPersistedBooleanProperty(.isCodelessDebugLogEnabled) }
    set { setPersistedBooleanProperty(.isCodelessDebugLogEnabled, to: newValue) }
  }

  // swiftlint:disable:next identifier_name discouraged_optional_boolean
  var _isCodelessDebugLogEnabled: Bool?

  /**
   Controls the access to IDFA.

   The default value is `true`.
   */
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isAdvertiserIDCollectionEnabled` instead.
      """
  )
  public var advertiserIDCollectionEnabled: Bool {
    get { isAdvertiserIDCollectionEnabled }
    set { isAdvertiserIDCollectionEnabled = newValue }
  }

  /**
   Controls the access to IDFA.

   The default value is `true`.
   */
  public var isAdvertiserIDCollectionEnabled: Bool {
    get { getPersistedBooleanProperty(.isAdvertiserIDCollectionEnabled) }
    set { setPersistedBooleanProperty(.isAdvertiserIDCollectionEnabled, to: newValue) }
  }

  // swiftlint:disable:next identifier_name discouraged_optional_boolean
  var _isAdvertiserIDCollectionEnabled: Bool?

  /**
   Controls the SKAdNetwork report.

   The default value is `true`.
   */
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isSKAdNetworkReportEnabled` instead.
      """
  )
  public var skAdNetworkReportEnabled: Bool {
    get { isSKAdNetworkReportEnabled }
    set { isSKAdNetworkReportEnabled = newValue }
  }

  /**
   Controls the SKAdNetwork report.

   The default value is `true`.
   */
  public var isSKAdNetworkReportEnabled: Bool {
    get { _isSKAdNetworkReportEnabled }
    set {
      validateConfiguration()
      _isSKAdNetworkReportEnabled = newValue
      // swiftformat:disable:this redundantSelf
      self.dataStore?.fb_setObject(newValue, forKey: PersistenceKey.isSKAdNetworkReportEnabled.rawValue)
      logIfSDKSettingsChanged()
    }
  }

  private lazy var _isSKAdNetworkReportEnabled: Bool = {
    let key = PersistenceKey.isSKAdNetworkReportEnabled.rawValue
    return self.dataStore?.fb_object(forKey: key) as? Bool
      ?? self.infoDictionaryProvider?.fb_object(forInfoDictionaryKey: key) as? Bool
      ?? true
  }()

  /**
   Whether data such as that generated through `AppEvents` and sent to Facebook
   should be restricted from being used for purposes other than analytics and conversions.

   The default value is `false`. This value is stored on the device and persists across app launches.
   */
  public var isEventDataUsageLimited: Bool {
    get { _isEventDataUsageLimited }
    set {
      _isEventDataUsageLimited = newValue
      // swiftformat:disable:this redundantSelf
      self.dataStore?.fb_setObject(newValue, forKey: PersistenceKey.limitEventAndDataUsage.rawValue)
    }
  }

  private lazy var _isEventDataUsageLimited = self.dataStore?
    .fb_object(forKey: PersistenceKey.limitEventAndDataUsage.rawValue) as? Bool
    ?? false

  /**
   Whether in-memory cached values should be used for expensive metadata fields, such as
   carrier and advertiser ID, that are fetched on many `applicationDidBecomeActive` notifications.

   The default value is `false`. This value is stored on the device and persists across app launches.
   */
  public var shouldUseCachedValuesForExpensiveMetadata: Bool {
    get { _shouldUseCachedValuesForExpensiveMetadata }
    set {
      _shouldUseCachedValuesForExpensiveMetadata = newValue
      self.dataStore?.fb_setObject(newValue, forKey: PersistenceKey.useCachedValuesForExpensiveMetadata.rawValue)
    }
  }

  private lazy var _shouldUseCachedValuesForExpensiveMetadata = self.dataStore?
    .fb_object(forKey: PersistenceKey.useCachedValuesForExpensiveMetadata.rawValue) as? Bool
    ?? false

  /// Controls error recovery for all `GraphRequest` instances created after the value is changed.
  public var isGraphErrorRecoveryEnabled = true

  /**
   The Facebook App ID used by the SDK.

   The default value will be read from the application's plist (FacebookAppID).
   */
  public var appID: String? {
    get { _appID }
    set {
      validateConfiguration()
      _appID = newValue
      logIfSDKSettingsChanged()
    }
  }

  private lazy var _appID = self.infoDictionaryProvider?
    .fb_object(forInfoDictionaryKey: PersistenceKey.appID.rawValue) as? String

  /**
   The default URL scheme suffix used for sessions.

   The default value will be read from the application's plist (FacebookUrlSchemeSuffix).
   */
  public var appURLSchemeSuffix: String? {
    get { getPersistedStringProperty(.appURLSchemeSuffix) }
    set { setPersistedStringProperty(.appURLSchemeSuffix, to: newValue) }
  }

  // swiftlint:disable:next identifier_name
  var _appURLSchemeSuffix: String?

  /**
   The client token needed for certain anonymous API calls (i.e., those made without a user-based access token).

   An app's client token can be found by navigating to https://developers.facebook.com/apps/YOUR-APP-ID
   (replacing "YOUR-APP-ID" with your actual app ID), choosing "Settings->Advanced" and scrolling to the "Security".

   The default value will be read from the application's plist (FacebookClientToken).
   */
  public var clientToken: String? {
    get { getPersistedStringProperty(.clientToken) }
    set { setPersistedStringProperty(.clientToken, to: newValue) }
  }

  // swiftlint:disable:next identifier_name
  var _clientToken: String?

  /**
   The Facebook Display Name used by the SDK.

   This should match the Display Name that has been set for the app with the corresponding Facebook App ID
   in the Facebook App Dashboard.

   The default value will be read from the application's plist (FacebookDisplayName).
   */
  public var displayName: String? {
    get { getPersistedStringProperty(.displayName) }
    set { setPersistedStringProperty(.displayName, to: newValue) }
  }

  // swiftlint:disable:next identifier_name
  var _displayName: String?
  /**
   The Facebook domain part. This can be used to change the Facebook domain
   (e.g. "beta") so that requests will be sent to `graph.beta.facebook.com`.

   The default value will be read from the application's plist (FacebookDomainPart).
   */
  public var facebookDomainPart: String? {
    get { getPersistedStringProperty(.facebookDomainPart) }
    set { setPersistedStringProperty(.facebookDomainPart, to: newValue) }
  }

  // swiftlint:disable:next identifier_name
  var _facebookDomainPart: String?

  /**
   Overrides the default Graph API version to use with `GraphRequest` instances.

   The string should be of the form `"v2.7"`.

   The default value is `defaultGraphAPIVersion`.
   */
  public lazy var graphAPIVersion = defaultGraphAPIVersion

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var userAgentSuffix: String?

  /**
   Controls the advertiser tracking status of the data sent to Facebook.

   The default value is `false`.
   */
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isAdvertiserTrackingEnabled` instead.
      """
  )
  public var advertiserTrackingEnabled: Bool {
    get { isAdvertiserTrackingEnabled }
    set { isAdvertiserTrackingEnabled = newValue }
  }

  /**
   Controls the advertiser tracking status of the data sent to Facebook.

   The default value is `false`.
   */
  public var isAdvertiserTrackingEnabled: Bool {
    get { advertisingTrackingStatus == .allowed }
    set(isNewlyAllowed) {
      if #available(iOS 14.0, *) {
        advertisingTrackingStatus = isNewlyAllowed ? .allowed : .disallowed
        recordSetAdvertiserTrackingEnabled()
      }
    }
  }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var advertisingTrackingStatus: AdvertisingTrackingStatus {
    get {
      if #available(iOS 14, *) {
        return _advertisingTrackingStatus
      } else {
        return ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? .allowed : .disallowed
      }
    }
    set {
      _advertisingTrackingStatus = newValue
      self.dataStore?.fb_setObject(newValue.rawValue, forKey: PersistenceKey.advertisingTrackingStatus.rawValue)
    }
  }

  private lazy var _advertisingTrackingStatus: AdvertisingTrackingStatus = {
    guard let dependencies = try? getDependencies() else { return .unspecified }

    if let persisted = dependencies.dataStore
      .fb_object(forKey: PersistenceKey.advertisingTrackingStatus.rawValue) as? NSNumber {
      return AdvertisingTrackingStatus(rawValue: persisted.uintValue) ?? .unspecified
    } else {
      return dependencies.appEventsConfigurationProvider.cachedAppEventsConfiguration.defaultATEStatus
    }
  }()

  private static let isDataProcessingRestrictedOption = "ldu"

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var isDataProcessingRestricted: Bool {
    guard let options = persistableDataProcessingOptions?[DataProcessingOptionKey.options.rawValue] as? [String] else {
      return false
    }

    return options.contains {
      $0.caseInsensitiveCompare(Self.isDataProcessingRestrictedOption) == .orderedSame
    }
  }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public private(set) lazy var persistableDataProcessingOptions: [DataProcessingOptionKey.RawValue: Any]? = {
    guard let data = self.dataStore?.fb_object(forKey: PersistenceKey.dataProcessingOptions.rawValue) as? Data else {
      return nil
    }

    let classes: [AnyClass] = [
      NSString.self,
      NSNumber.self,
      NSArray.self,
      NSDictionary.self,
      NSSet.self,
    ]

    return try? NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: data)
      as? [DataProcessingOptionKey.RawValue: Any]
  }()

  /**
   Set the data processing options.

   - Parameter options: The list of options.
   */
  public func setDataProcessingOptions(_ options: [String]?) {
    setDataProcessingOptions(options, country: 0, state: 0)
  }

  /**
   Sets the data processing options.

   - Parameters:
     - options The list of the options.
     - country The code for the country.
     - state The code for the state.
   */
  public func setDataProcessingOptions(_ options: [String]?, country: Int32, state: Int32) {
    let values: [DataProcessingOptionKey.RawValue: Any] = [
      DataProcessingOptionKey.options.rawValue: options ?? [],
      DataProcessingOptionKey.country.rawValue: country,
      DataProcessingOptionKey.state.rawValue: state,
    ]

    persistableDataProcessingOptions = values
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: values, requiringSecureCoding: false) {
      self.dataStore?.fb_setObject(data, forKey: PersistenceKey.dataProcessingOptions.rawValue)
    }
  }

  /**
   The current Facebook SDK logging behavior. This should consist of strings
   defined as constants with `LoggingBehavior` that indicate what information should be logged.

   Set to an empty set in order to disable all logging.

   You can also define this via an array in your app's plist with the key "FacebookLoggingBehavior"; or add/remove
   individual values via `enableLoggingBehavior(_:)` or `disableLoggingBehavior(_:)`

   The default value is `[.developerErrors]`.
   */
  public var loggingBehaviors: Set<LoggingBehavior> {
    get { _loggingBehaviors }
    set {
      _loggingBehaviors = newValue
      updateGraphAPIDebugBehavior()
    }
  }

  private lazy var _loggingBehaviors: Set<LoggingBehavior> = {
    if let persisted = self.infoDictionaryProvider?
      .fb_object(forInfoDictionaryKey: PersistenceKey.loggingBehaviors.rawValue) as? [LoggingBehavior] {
      return Set(persisted)
    } else {
      // Establish set of default enabled logging behaviors.  You can completely disable logging by
      // specifying an empty array for FacebookLoggingBehavior in your Info.plist.
      return [.developerErrors]
    }
  }()

  /**
   Enable a particular Facebook SDK logging behavior.

   - Parameter loggingBehavior: The logging behavior to enable. This should be a string constant defined
   as a `LoggingBehavior`.
   */
  public func enableLoggingBehavior(_ loggingBehavior: LoggingBehavior) {
    loggingBehaviors.insert(loggingBehavior)
  }

  /**
   Disable a particular Facebook SDK logging behavior.

   - Parameter loggingBehavior: The logging behavior to disable. This should be a string constant defined
   as a `LoggingBehavior`.
   */
  public func disableLoggingBehavior(_ loggingBehavior: LoggingBehavior) {
    loggingBehaviors.remove(loggingBehavior)
  }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var shouldUseTokenOptimizations: Bool {
    get { _shouldUseTokenOptimizations }
    set {
      _shouldUseTokenOptimizations = newValue
      self.dataStore?.fb_setObject(newValue, forKey: PersistenceKey.useTokenOptimizations.rawValue)
    }
  }

  private lazy var _shouldUseTokenOptimizations = self.dataStore?
    .fb_object(forKey: PersistenceKey.useTokenOptimizations.rawValue) as? Bool
    ?? true

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isATETimeSufficientlyDelayed` instead.
      """
  )
  public var isSetATETimeExceedsInstallTime: Bool { isATETimeSufficientlyDelayed }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var isATETimeSufficientlyDelayed: Bool {
    guard
      let installTimestamp = installTimestamp,
      let ateTimestamp = advertiserTrackingEnabledTimestamp
    else { return false }

    let oneDayInSeconds: TimeInterval = 60.0 /* seconds */ * 60.0 /* minutes */ * 24.0 /* hours */
    return ateTimestamp.timeIntervalSince(installTimestamp) > oneDayInSeconds
  }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var installTimestamp: Date? {
    self.dataStore?.fb_object(forKey: PersistenceKey.installTimestamp.rawValue) as? Date
  }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var advertiserTrackingEnabledTimestamp: Date? {
    self.dataStore?.fb_object(forKey: PersistenceKey.setAdvertiserTrackingEnabledTimestamp.rawValue) as? Date
  }

  private func updateGraphAPIDebugBehavior() {
    // Enable warnings every time info is enabled
    if loggingBehaviors.contains(.graphAPIDebugInfo) {
      loggingBehaviors.insert(.graphAPIDebugWarning)
    }
  }

  private enum GraphAPIDebugParameterValue: String {
    case info
    case warning
  }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `graphAPIDebugParameterValue` instead.
      """
  )
  public var graphAPIDebugParamValue: String? { graphAPIDebugParameterValue }

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public var graphAPIDebugParameterValue: String? {
    if loggingBehaviors.contains(.graphAPIDebugInfo) {
      return GraphAPIDebugParameterValue.info.rawValue
    } else if loggingBehaviors.contains(.graphAPIDebugWarning) {
      return GraphAPIDebugParameterValue.warning.rawValue
    } else {
      return nil
    }
  }

  // swiftlint:enable let_var_whitespace

  #if DEBUG
  func reset() {
    _loggingBehaviors = [.developerErrors]
    resetDependencies()
  }
  #endif
}

// MARK: - Dependencies

extension Settings: DependentAsObject {
  struct ObjectDependencies {
    var appEventsConfigurationProvider: _AppEventsConfigurationProviding
    var dataStore: DataPersisting
    var eventLogger: EventLogging
    var infoDictionaryProvider: InfoDictionaryProviding
  }

  func validateConfiguration() {
    #if DEBUG
    // swiftlint:disable:next statement_position
    do { _ = try getDependencies() }
    catch { fatalError(Self.unconfiguredDebugMessage) }
    #endif
  }

  static let unconfiguredDebugMessage = """
    As of v9.0, you must initialize the SDK prior to calling any methods or setting any properties. \
    You can do this by calling `ApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`. \
    Learn more: https://developers.facebook.com/docs/ios/getting-started. \
    If no `UIApplication` instance is available, you can use `ApplicationDelegate.initializeSDK()`.
    """
}
