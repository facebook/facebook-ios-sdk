/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import CommonCrypto.CommonHMAC
import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMInvocation)
public class _AEMInvocation: NSObject, NSSecureCoding { // swiftlint:disable:this prefer_final_classes

  public internal(set) var campaignID: String
  public let acsToken: String
  var acsSharedSecret: String?
  public internal(set) var acsConfigurationID: String?
  public internal(set) var businessID: String?
  public internal(set) var catalogID: String?
  public let isTestMode: Bool
  public var hasStoreKitAdNetwork: Bool
  public var isConversionFilteringEligible: Bool
  private(set) var timestamp: Date
  private(set) var configurationMode: String
  /// The unique identifier of the configuration, it's the same as configuration's validFrom
  public internal(set) var configurationID: Int
  var recordedEvents: Set<String>
  var recordedValues: [String: [String: Any]]
  public internal(set) var conversionValue: Int
  var priority: Int
  var conversionTimestamp: Date?
  public var isAggregated: Bool

  private static let secondsInDay = 24 /* hours */ * 60 /* minutes */ * 60 /* seconds */
  private static let catalogOptimizationModulus = 8
  private static let topOutPriority = 32

  private enum Key: String {
    case campaignIdentifier = "campaign_ids"
    case acsToken = "acs_token"
    case acsSharedSecret = "shared_secret"
    case acsConfigurationIdentifier = "acs_config_id"
    case businessIdentifier = "advertiser_id"
    case catalogIdentifier = "catalog_id"
    case testDeepLink = "test_deeplink"
    case timestamp
    case configurationMode = "config_mode"
    case configurationIdentifier = "config_id"
    case recordedEvents = "recorded_events"
    case recordedValues = "recorded_values"
    case conversionValue = "conversion_value"
    case priority
    case conversionTimestamp = "conversion_timestamp"
    case isAggregated = "is_aggregated"
    case hasStoreKitAdNetwork = "has_skan"
    case isConversionFilteringEligible = "is_conversion_filtering_eligible"
    case facebookContent = "fb_content"
    case facebookContentIdentifier = "fb_content_id"
  }

  enum ConfigurationMode: String {
    case `default` = "DEFAULT"
    case brand = "BRAND"
    case cpas = "CPAS"
  }

  public convenience init?(appLinkData: [AnyHashable: Any]?) {
    guard
      let appLinkData = appLinkData,
      let campaignID = appLinkData[Key.campaignIdentifier.rawValue] as? String,
      let acsToken = appLinkData[Key.acsToken.rawValue] as? String
    else { return nil }

    let acsSharedSecret = appLinkData[Key.acsSharedSecret.rawValue] as? String
    let acsConfigurationID = appLinkData[Key.configurationIdentifier.rawValue] as? String
    let businessID = appLinkData[Key.businessIdentifier.rawValue] as? String
    let catalogID = appLinkData[Key.catalogIdentifier.rawValue] as? String
    let isTestMode = (appLinkData[Key.testDeepLink.rawValue] as? NSNumber)?.boolValue ?? false
    let hasStoreKitAdNetwork = (appLinkData[Key.hasStoreKitAdNetwork.rawValue] as? NSNumber)?.boolValue ?? false

    self.init(
      campaignID: campaignID,
      acsToken: acsToken,
      acsSharedSecret: acsSharedSecret,
      acsConfigurationID: acsConfigurationID,
      businessID: businessID,
      catalogID: catalogID,
      isTestMode: isTestMode,
      hasStoreKitAdNetwork: hasStoreKitAdNetwork,
      isConversionFilteringEligible: true
    )
  }

  convenience init?(
    campaignID: String,
    acsToken: String,
    acsSharedSecret: String?,
    acsConfigurationID: String?,
    businessID: String?,
    catalogID: String?,
    isTestMode: Bool,
    hasStoreKitAdNetwork: Bool,
    isConversionFilteringEligible: Bool
  ) {
    self.init(
      campaignID: campaignID,
      acsToken: acsToken,
      acsSharedSecret: acsSharedSecret,
      acsConfigurationID: acsConfigurationID,
      businessID: businessID,
      catalogID: catalogID,
      timestamp: nil,
      configurationMode: "DEFAULT",
      configurationID: -1,
      recordedEvents: nil,
      recordedValues: nil,
      conversionValue: -1,
      priority: -1,
      conversionTimestamp: nil,
      isAggregated: true,
      isTestMode: isTestMode,
      hasStoreKitAdNetwork: hasStoreKitAdNetwork,
      isConversionFilteringEligible: isConversionFilteringEligible
    )
  }

  init?(
    campaignID: String,
    acsToken: String,
    acsSharedSecret: String?,
    acsConfigurationID: String?,
    businessID: String?,
    catalogID: String?,
    timestamp: Date?,
    configurationMode: String,
    configurationID: Int,
    recordedEvents: Set<String>?,
    recordedValues: [String: [String: Any]]?,
    conversionValue: Int,
    priority: Int,
    conversionTimestamp: Date?,
    isAggregated: Bool,
    isTestMode: Bool,
    hasStoreKitAdNetwork: Bool,
    isConversionFilteringEligible: Bool
  ) {
    self.campaignID = campaignID
    self.acsToken = acsToken
    self.acsSharedSecret = acsSharedSecret
    self.acsConfigurationID = acsConfigurationID
    self.businessID = businessID
    self.catalogID = catalogID
    self.timestamp = timestamp ?? Date()
    self.configurationMode = configurationMode
    self.configurationID = configurationID
    self.recordedEvents = recordedEvents ?? []
    self.recordedValues = recordedValues ?? [:]
    self.conversionValue = conversionValue
    self.priority = priority
    self.conversionTimestamp = conversionTimestamp
    self.isAggregated = isAggregated
    self.isTestMode = isTestMode
    self.hasStoreKitAdNetwork = hasStoreKitAdNetwork
    self.isConversionFilteringEligible = isConversionFilteringEligible

    super.init()
  }

  @discardableResult
  // swiftlint:disable:next function_parameter_count
  public func attributeEvent(
    _ event: String,
    currency potentialValueCurrency: String?,
    value potentialValue: NSNumber?,
    parameters: [String: Any]?,
    configurations: [String: [_AEMConfiguration]]?,
    shouldUpdateCache: Bool,
    isRuleMatchInServer: Bool
  ) -> Bool {
    guard
      let configuration = findConfiguration(in: configurations),
      !isOutOfWindow(configuration: configuration),
      configuration.eventSet.contains(event)
    else { return false }

    var processedParameters: [String: Any]?
    if !isRuleMatchInServer {
      // Check advertiser rule matching
      processedParameters = getProcessedParameters(from: parameters)
      if let matchingRule = configuration.matchingRule,
          !matchingRule.isMatchedEventParameters(processedParameters) {
        return false
      }
    }

    var isAttributed = false

    if !recordedEvents.contains(event) {
      if shouldUpdateCache {
        recordedEvents.insert(event)
      }

      isAttributed = true
    }

    // Change currency to default currency if currency is not found in currencySet
    var valueCurrency = configuration.defaultCurrency
    if let currency = potentialValueCurrency?.uppercased(),
       configuration.currencySet.contains(currency) {
      valueCurrency = currency
    }

    var value = potentialValue
    if !isRuleMatchInServer {
      // Use in-segment value for CPAS
      if configuration.mode == ConfigurationMode.cpas.rawValue {
        value = _AEMUtility.shared.getInSegmentValue(processedParameters, matchingRule: configuration.matchingRule)
      }
    }

    if let value = value {
      var mapping = recordedValues[event] ?? [:]
      let valueInMapping = (mapping[valueCurrency] as? NSNumber)?.doubleValue ?? 0.0

      // Overwrite values when the incoming event's value is greater than the cached one
      if value.doubleValue > valueInMapping {
        if shouldUpdateCache {
          mapping[valueCurrency] = value
          recordedValues[event] = mapping
        }

        isAttributed = true
      }
    }

    return isAttributed
  }

  public func updateConversionValue(
    configurations: [String: [_AEMConfiguration]]?,
    event: String,
    shouldBoostPriority: Bool
  ) -> Bool {
    guard let configuration = findConfiguration(in: configurations)
    else { return false }

    var isConversionValueUpdated = false

    // Update conversion value if a rule is matched
    for rule in configuration.conversionValueRules {
      var rulePriority = rule.priority

      if isConversionFilteringEligible,
         shouldBoostPriority,
         rule.containsEvent(event),
         isOptimizedEvent(event, configuration: configuration) {
        rulePriority += Self.topOutPriority
      }

      guard rulePriority > priority else { continue }

      if rule.isMatched(withRecordedEvents: recordedEvents, recordedValues: recordedValues) {
        conversionValue = rule.conversionValue
        priority = rulePriority
        conversionTimestamp = Date()
        isAggregated = false
        isConversionValueUpdated = true
      }
    }

    return isConversionValueUpdated
  }

  public func isOptimizedEvent(_ event: String, configurations: [String: [_AEMConfiguration]]?) -> Bool {
    guard
      catalogID != nil,
      let configuration = findConfiguration(in: configurations)
    else { return false }

    return isOptimizedEvent(event, configuration: configuration)
  }

  private func isOptimizedEvent(_ event: String, configuration: _AEMConfiguration) -> Bool {
    // Look up conversion bit mapping to check if an event is optimized
    configuration.conversionValueRules.contains { rule in
      guard
        let campaign = Int(campaignID),
        (campaign % Self.catalogOptimizationModulus) == (rule.conversionValue % Self.catalogOptimizationModulus)
      else { return false }

      return rule.events.contains { $0.eventName == event }
    }
  }

  public func isOutOfWindow(configurations: [String: [_AEMConfiguration]]?) -> Bool {
    isOutOfWindow(configuration: findConfiguration(in: configurations))
  }

  // Second attempt

  public func getHMAC(delay: Int) -> String? {
    guard
      acsConfigurationID != nil,
      let secretKey = acsSharedSecret,
      let secretKeyData = decodeBase64URLSafeString(secretKey),
      let hmac = NSMutableData(length: Int(CC_SHA512_DIGEST_LENGTH))
    else { return nil }

    let message = "\(campaignID)|\(conversionValue)|\(delay)|server"
    guard let messageData = message.data(using: .utf8) else { return nil }

    let secretKeyNSData = NSData(data: secretKeyData)
    let messageNSData = NSData(data: messageData)

    CCHmac(
      CCHmacAlgorithm(kCCHmacAlgSHA512),
      secretKeyNSData.bytes,
      secretKeyNSData.length,
      messageNSData.bytes,
      messageNSData.length,
      hmac.mutableBytes
    )

    return hmac
      .base64EncodedString()
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "=", with: "")
  }

  func decodeBase64URLSafeString(_ string: String) -> Data? {
    guard !string.isEmpty else { return nil }

    let length = string.count
    let paddedLength = length + (4 - (length % 4))
    let decoded = string
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
      .padding(toLength: paddedLength, withPad: "=", startingAt: 0)

    return Data(base64Encoded: decoded)
  }

  func getProcessedParameters(from parameters: [String: Any]?) -> [String: Any]? {
    guard var processed = parameters else { return nil }

    if let content = processed[Key.facebookContent.rawValue] as? String,
       let contentData = content.data(using: .utf8),
       let jsonObject = try? JSONSerialization.jsonObject(with: contentData) {
      processed[Key.facebookContent.rawValue] = jsonObject
    }

    if let contentID = processed[Key.facebookContentIdentifier.rawValue] as? String,
       let stringData = contentID.data(using: .utf8),
       let data = try? JSONSerialization.jsonObject(with: stringData) {
      processed[Key.facebookContentIdentifier.rawValue] = data
    }

    return processed
  }

  private func isOutOfWindow(configuration: _AEMConfiguration?) -> Bool {
    guard let configuration = configuration else { return true }

    let cutoff = TimeInterval(configuration.cutoffTime * Self.secondsInDay)
    let isCutoff = Date().timeIntervalSince(timestamp) > cutoff

    var isOverLastConversionWindow = false
    if let conversionTimestamp = conversionTimestamp {
      let oneDay = TimeInterval(Self.secondsInDay)
      isOverLastConversionWindow = Date().timeIntervalSince(conversionTimestamp) > oneDay
    }

    return isCutoff || isOverLastConversionWindow
  }

  func findConfiguration(in configurations: [String: [_AEMConfiguration]]?) -> _AEMConfiguration? {
    let configurationMode = (businessID != nil) ? ConfigurationMode.brand : .default
    let configurationList = getConfigurationList(mode: configurationMode, configurations: configurations)

    guard !configurationList.isEmpty else { return nil }

    if configurationID > 0 {
      return configurationList.first {
        $0.isSame(validFrom: configurationID, businessID: businessID)
      }
    } else {
      let configuration = configurationList.reversed().first {
        TimeInterval($0.validFrom) <= timestamp.timeIntervalSince1970
          && $0.isSameBusinessID(businessID)
      }

      if let configuration = configuration {
        setConfiguration(configuration)
      }

      return configuration
    }
  }

  func getConfigurationList(
    mode: ConfigurationMode,
    configurations: [String: [_AEMConfiguration]]?
  ) -> [_AEMConfiguration] {
    guard let configurations = configurations else { return [] }

    if mode == .brand {
      return (configurations[ConfigurationMode.cpas.rawValue] ?? [])
        + (configurations[ConfigurationMode.brand.rawValue] ?? [])
    } else {
      return configurations[mode.rawValue] ?? []
    }
  }

  func setConfiguration(_ configuration: _AEMConfiguration) {
    configurationID = configuration.validFrom
    configurationMode = configuration.mode
  }

  // MARK: - NSCoding

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder decoder: NSCoder) {
    guard
      let campaignID = decoder.decodeObject(of: NSString.self, forKey: Key.campaignIdentifier.rawValue),
      let acsToken = decoder.decodeObject(of: NSString.self, forKey: Key.acsToken.rawValue),
      let configurationMode = decoder.decodeObject(of: NSString.self, forKey: Key.configurationMode.rawValue)
    else { return nil }

    let acsSharedSecret = decoder.decodeObject(of: NSString.self, forKey: Key.acsSharedSecret.rawValue)
    let acsConfigurationID = decoder.decodeObject(of: NSString.self, forKey: Key.acsConfigurationIdentifier.rawValue)
    let businessID = decoder.decodeObject(of: NSString.self, forKey: Key.businessIdentifier.rawValue)
    let catalogID = decoder.decodeObject(of: NSString.self, forKey: Key.catalogIdentifier.rawValue)
    let timestamp = decoder.decodeObject(of: NSDate.self, forKey: Key.timestamp.rawValue) ?? NSDate()
    let configurationID = decoder.decodeInteger(forKey: Key.configurationIdentifier.rawValue)
    let recordedEvents = decoder.decodeObject(
      of: [NSSet.self, NSString.self],
      forKey: Key.recordedEvents.rawValue
    ) as? NSSet
    let recordedValues = decoder.decodeObject(
      of: [NSDictionary.self, NSString.self, NSNumber.self],
      forKey: Key.recordedValues.rawValue
    ) as? [String: [String: Any]]
    let conversionValue = decoder.decodeInteger(forKey: Key.conversionValue.rawValue)
    let priority = decoder.decodeInteger(forKey: Key.priority.rawValue)
    let conversionTimestamp = decoder.decodeObject(of: NSDate.self, forKey: Key.conversionTimestamp.rawValue)
    let isAggregated = decoder.decodeBool(forKey: Key.isAggregated.rawValue)
    let hasStoreKitAdNetwork = decoder.decodeBool(forKey: Key.hasStoreKitAdNetwork.rawValue)
    let isConversionFilteringEligible = decoder.decodeBool(forKey: Key.isConversionFilteringEligible.rawValue)

    self.campaignID = campaignID as String
    self.acsToken = acsToken as String
    self.acsSharedSecret = acsSharedSecret as String?
    self.acsConfigurationID = acsConfigurationID as String?
    self.businessID = businessID as String?
    self.catalogID = catalogID as String?
    self.timestamp = timestamp as Date
    self.configurationMode = configurationMode as String
    self.configurationID = configurationID
    self.recordedEvents = (recordedEvents as? Set<String>) ?? []
    self.recordedValues = recordedValues ?? [:]
    self.conversionValue = conversionValue
    self.priority = priority
    self.conversionTimestamp = conversionTimestamp as Date?
    self.isAggregated = isAggregated
    isTestMode = false
    self.hasStoreKitAdNetwork = hasStoreKitAdNetwork
    self.isConversionFilteringEligible = isConversionFilteringEligible
  }

  public func encode(with encoder: NSCoder) {
    encoder.encode(campaignID, forKey: Key.campaignIdentifier.rawValue)
    encoder.encode(acsToken, forKey: Key.acsToken.rawValue)
    encoder.encode(acsSharedSecret, forKey: Key.acsSharedSecret.rawValue)
    encoder.encode(acsConfigurationID, forKey: Key.acsConfigurationIdentifier.rawValue)
    encoder.encode(businessID, forKey: Key.businessIdentifier.rawValue)
    encoder.encode(catalogID, forKey: Key.catalogIdentifier.rawValue)
    encoder.encode(timestamp, forKey: Key.timestamp.rawValue)
    encoder.encode(configurationMode, forKey: Key.configurationMode.rawValue)
    encoder.encode(configurationID, forKey: Key.configurationIdentifier.rawValue)
    encoder.encode(recordedEvents, forKey: Key.recordedEvents.rawValue)
    encoder.encode(recordedValues, forKey: Key.recordedValues.rawValue)
    encoder.encode(conversionValue, forKey: Key.conversionValue.rawValue)
    encoder.encode(priority, forKey: Key.priority.rawValue)
    encoder.encode(conversionTimestamp, forKey: Key.conversionTimestamp.rawValue)
    encoder.encode(isAggregated, forKey: Key.isAggregated.rawValue)
    encoder.encode(hasStoreKitAdNetwork, forKey: Key.hasStoreKitAdNetwork.rawValue)
    encoder.encode(isConversionFilteringEligible, forKey: Key.isConversionFilteringEligible.rawValue)
  }

  #if DEBUG
  func reset() {
    timestamp = Date()
    configurationMode = "DEFAULT"
    configurationID = -1
    businessID = nil
    catalogID = nil
    recordedEvents = []
    recordedValues = [:]
    conversionValue = -1
    priority = -1
    conversionTimestamp = Date()
    isAggregated = true
    hasStoreKitAdNetwork = false
    isConversionFilteringEligible = true
  }
  #endif
}

#endif
