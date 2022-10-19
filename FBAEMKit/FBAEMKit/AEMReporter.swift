/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit_Basics
import Foundation

// swiftlint:disable:next swiftlint_disable_without_this_or_next
// swiftlint:disable identifier_name

typealias FBAEMReporterBlock = (NSError?) -> Void

private let FB_AEM_CONFIG_TIME_OUT: TimeInterval = 86400
private let FB_AEM_DELAY: TimeInterval = 3

private let BUSINESS_ID_KEY = "advertiser_id"
private let BUSINESS_IDS_KEY = "advertiser_ids"
private let FB_CONTENT_DATA_KEY = "fb_content_data"
private let AL_APPLINK_DATA_KEY = "al_applink_data"
private let CAMPAIGN_ID_KEY = "campaign_id"
private let CONVERSION_DATA_KEY = "conversion_data"
private let CONSUMPTION_HOUR_KEY = "consumption_hour"
private let TOKEN_KEY = "token"
private let HMAC_KEY = "hmac"
private let CONFIG_ID_KEY = "config_id"
private let DELAY_FLOW_KEY = "delay_flow"
private let IS_CONVERSION_FILTERING_KEY = "is_conversion_filtering"
private let FB_CONTENT_IDS_KEY = "fb_content_ids"
private let CATALOG_ID_KEY = "catalog_id"

private let FBAEMConfigurationKey = "com.facebook.sdk:FBSDKAEMConfiguration"
private let FBAEMReporterKey = "com.facebook.sdk:FBSDKAEMReporter"
private let FBAEMMINAggregationRequestTimestampKey = "com.facebook.sdk:FBAEMMinAggregationRequestTimestamp"
private let FBAEMReporterFileName = "FBSDKAEMReportData.report"
private let FBAEMConfigFileName = "FBSDKAEMReportData.config"
private let FBAEMHTTPMethodGET = "GET"
private let FBAEMHTTPMethodPOST = "POST"

@objcMembers
@objc(FBAEMReporter)
public final class AEMReporter: NSObject {
  static var networker: AEMNetworking?
  static var appID: String?
  static let nullAppID = "(null)" // Objective-C uses "(null)" if there are nil objects in an interpolated string
  static var analyticsAppID: String?
  static var reporter: SKAdNetworkReporting?
  static var dataStore: DataPersisting?

  static var isAEMReportEnabled = false
  static var isLoadingConfiguration = false
  static var isConversionFilteringEnabled = false
  static var isCatalogMatchingEnabled = false
  static var isAdvertiserRuleMatchInServerEnabled = false
  static let dispatchQueueLabel = "com.facebook.appevents.AEM.FBAEMReporter"
  static var serialQueue = DispatchQueue(label: dispatchQueueLabel)
  static var reportFile: String?
  private static var configFile: String?
  static var configurations: [String: [_AEMConfiguration]] = [:]
  static var invocations: [_AEMInvocation] = []
  static var configRefreshTimestamp: Date?
  static var minAggregationRequestTimestamp: Date?
  static var completionBlocks: [FBAEMReporterBlock] = []

  static func configure(
    networker: AEMNetworking?,
    appID: String?,
    reporter: SKAdNetworkReporting?
  ) {
    configure(
      networker: networker,
      appID: appID,
      reporter: reporter,
      analyticsAppID: nil
    )
  }

  private static func configure(
    networker: AEMNetworking?,
    appID: String?,
    reporter: SKAdNetworkReporting?,
    analyticsAppID: String?
  ) {
    configure(
      networker: networker,
      appID: appID,
      reporter: reporter,
      analyticsAppID: analyticsAppID,
      store: UserDefaults.standard
    )
  }

  static func configure(
    networker: AEMNetworking?,
    appID: String?,
    reporter: SKAdNetworkReporting?,
    analyticsAppID: String?,
    store: DataPersisting?
  ) {
    Self.networker = networker
    Self.appID = appID
    Self.reporter = reporter
    Self.analyticsAppID = analyticsAppID
    Self.dataStore = store
  }

  /**
   Enable AEM reporting

   This function should be called in application(_:open:options:) from ApplicationDelegate
   */
  public static func enable() {
    guard
      #available(iOS 14.0, *),
      !isAEMReportEnabled
    else {
      return
    }

    isAEMReportEnabled = true

    _AEMConfiguration.configure(withRuleProvider: _AEMAdvertiserRuleFactory())
    reportFile = BasicUtility.persistenceFilePath(FBAEMReporterFileName)
    configFile = BasicUtility.persistenceFilePath(FBAEMConfigFileName)
    completionBlocks = []

    dispatchOnQueue(serialQueue) {
      minAggregationRequestTimestamp = _loadMinAggregationRequestTimestamp()
      configurations = _loadConfigurations()
      invocations = _loadReportData()
    }

    _loadConfiguration(withRefreshForced: false) { error in
      if error != nil {
        return
      }

      _sendAggregationRequest()
      _clearCache()
    }

    // If developers forget to call configureWithNetworker:appID:
    // or pass nil for networker,
    // we use default networker in FBAEMKit
    if networker == nil {
      let networker = _AEMNetworker()
      networker.userAgentSuffix = analyticsAppID
      self.networker = networker
    }

    // If developers forget to call configureWithNetworker:appID:,
    // we will look up app Any in plist file, key is FacebookAppID
    if appID == nil || appID?.isEmpty == true {
      appID = _AEMSettings.appID()
    }

    // If appID is still nil/empty, we don't enable AEM and throw warning here
    if appID == nil || appID?.isEmpty == true {
      // swiftlint:disable:next line_length
      print("App ID is not set up correctly, please call configureWithNetworker:appID: and pass correct FB App ID OR add FacebookAppID in Info.plist")
    }
  }

  /**
   Control whether to enable conversion filtering

   This function should be called in `application(_:open:options:)` from ApplicationDelegate
   */
  public static func setConversionFilteringEnabled(_ enabled: Bool) {
    isConversionFilteringEnabled = enabled
  }

  /**
   Control whether to enable catalog matching

   This function should be called in `application(_:open:options:)` from ApplicationDelegate
   */
  public static func setCatalogMatchingEnabled(_ enabled: Bool) {
    isCatalogMatchingEnabled = enabled
  }

  /**
   Control whether to enable advertiser rule match enabled in server side. This is expected
   to be called internally by FB SDK and will be removed in the future

   This function should be called in `application(_:open:options:)` from ApplicationDelegate
   */
  public static func setAdvertiserRuleMatchInServerEnabled(_ enabled: Bool) {
    isAdvertiserRuleMatchInServerEnabled = enabled
  }

  /**
   Handle deeplink

   This function should be called in `application(_:open:options:) `from ApplicationDelegate
   */
  public static func handle(_ url: URL) {
    guard
      isAEMReportEnabled,
      let invocation = parseURL(url)
    else {
      return
    }

    guard !invocation.isTestMode else {
      _sendDebuggingRequest(invocation)
      return
    }

    _loadConfiguration(withRefreshForced: true, block: nil)
    _appendAndSaveInvocation(invocation)
  }

  static func parseURL(_ url: URL?) -> _AEMInvocation? {
    guard let url = url else {
      return nil
    }

    let params = BasicUtility.dictionary(withQueryString: url.query ?? "")
    guard let applinkDataString = params[AL_APPLINK_DATA_KEY] else {
      return nil
    }

    guard let applinkData = try? BasicUtility.object(forJSONString: applinkDataString) as? [AnyHashable: Any] else {
      return nil
    }

    return _AEMInvocation(appLinkData: applinkData)
  }

  /**
   Calculate the conversion value for the app event based on the AEM configuration

   This function should be called when you log any in-app events
   */
  @objc(recordAndUpdateEvent:currency:value:parameters:)
  public static func recordAndUpdate(
    event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?
  ) {
    guard #available(iOS 14.0, *) else {
      return
    }

    if !isAEMReportEnabled || event.isEmpty {
      return
    }

    _loadConfiguration(withRefreshForced: false) { _ in
      if configurations.isEmpty || invocations.isEmpty {
        return
      }

      let businessIDs = _AEMUtility.shared.getBusinessIDsInOrder(invocations)
      if isAdvertiserRuleMatchInServerEnabled,
         let businessID = businessIDs.first,
         !businessID.isEmpty {
        self._loadRuleMatch(businessIDs, event: event, currency: currency, value: value, parameters: parameters)
      } else {
        self._attributionV1WithEvent(event, currency: currency, value: value, parameters: parameters)
      }
    }
  }

  private static func _attributionV1WithEvent(
    _ event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?
  ) {
    guard let attributedInvocation = _attributedInvocation(
      invocations,
      event: event,
      currency: currency,
      value: value,
      parameters: parameters,
      configurations: configurations
    ) else {
      return
    }

    _attributionWithInvocation(
      attributedInvocation,
      event: event,
      currency: currency,
      value: value,
      parameters: parameters,
      isRuleMatchInServer: false
    )
  }

  // swiftlint:disable:next function_parameter_count
  private static func _attributionWithInvocation(
    _ invocation: _AEMInvocation,
    event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?,
    isRuleMatchInServer: Bool
  ) {
    // We will report conversion in catalog level if
    // 1. conversion filtering and catalog matching are enabled
    // 2. invocation has catalog Any
    // 3. event is optimized
    // 4. event's content Any belongs to the catalog
    if _shouldReportConversion(inCatalogLevel: invocation, event: event) {
      let contentID = _AEMUtility.shared.getContentID(parameters)
      _loadCatalogOptimization(with: invocation, contentID: contentID) {
        self._updateAttributedInvocation(
          invocation,
          event: event,
          currency: currency,
          value: value,
          parameters: parameters,
          shouldBoostPriority: true,
          isRuleMatchInServer: isRuleMatchInServer
        )
      }
    } else {
      _updateAttributedInvocation(
        invocation,
        event: event,
        currency: currency,
        value: value,
        parameters: parameters,
        shouldBoostPriority: isConversionFilteringEnabled,
        isRuleMatchInServer: isRuleMatchInServer
      )
    }
  }

  // swiftlint:disable:next function_parameter_count
  private static func _updateAttributedInvocation(
    _ invocation: _AEMInvocation,
    event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?,
    shouldBoostPriority: Bool,
    isRuleMatchInServer: Bool
  ) {
    invocation.attributeEvent(
      event,
      currency: currency,
      value: value,
      parameters: parameters,
      configurations: configurations,
      shouldUpdateCache: true,
      isRuleMatchInServer: isRuleMatchInServer
    )

    if invocation.updateConversionValue(
      configurations: configurations,
      event: event,
      shouldBoostPriority: shouldBoostPriority
    ) {
      _sendAggregationRequest()
    }

    _saveReportData()
  }

  // swiftlint:disable:next function_parameter_count
  static func _attributedInvocation(
    _ invocations: [_AEMInvocation],
    event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?,
    configurations: [String: [_AEMConfiguration]]
  ) -> _AEMInvocation? {
    var isGeneralInvocationVisited = false
    var attributedInvocation: _AEMInvocation?
    for invocation in invocations.reversed() {
      if _isDoubleCounting(invocation, event: event) {
        break
      }

      if invocation.businessID == nil,
         isGeneralInvocationVisited {
        continue
      }

      if invocation.attributeEvent(
        event,
        currency: currency,
        value: value,
        parameters: parameters,
        configurations: configurations,
        shouldUpdateCache: false,
        isRuleMatchInServer: false
      ) {
        attributedInvocation = invocation
        break
      }

      if invocation.businessID == nil {
        isGeneralInvocationVisited = true
      }
    }
    return attributedInvocation
  }

  static func _isDoubleCounting(
    _ invocation: _AEMInvocation,
    event: String
  ) -> Bool {
    // We consider it as Double counting if following conditions meet simultaneously
    // 1. The field hasStoreKitAdNetwork is true
    // 2. The conversion happens before SKAdNetwork cutoff
    // 3. The event is also being reported by SKAdNetwork
    return invocation.hasStoreKitAdNetwork
      && reporter?.shouldCutoff() == false
      && reporter?.isReportingEvent(event) == true
  }

  private static func _appendAndSaveInvocation(_ invocation: _AEMInvocation) {
    dispatchOnQueue(serialQueue) {
      invocations.append(invocation)
      _saveReportData()
    }
  }

  static func _loadConfiguration(withRefreshForced forced: Bool, block: FBAEMReporterBlock?) {
    dispatchOnQueue(serialQueue) {
      if let block = block {
        completionBlocks.append(block)
      }

      // Executes blocks if there is cache
      if !_shouldRefresh(withIsForced: forced) {
        for executionBlock in completionBlocks {
          executionBlock(nil)
        }
        completionBlocks.removeAll()
        return
      }

      if isLoadingConfiguration {
        return
      }

      isLoadingConfiguration = true

      networker?.startGraphRequest(
        withGraphPath: "\(appID ?? nullAppID)/aem_conversion_configs",
        parameters: _requestParameters(),
        tokenString: nil,
        httpMethod: FBAEMHTTPMethodGET
      ) { result, error in
        dispatchOnQueue(serialQueue) {
          if let error = error {
            for executionBlock in completionBlocks {
              executionBlock(error as NSError)
            }
            completionBlocks.removeAll()
            isLoadingConfiguration = false
            return
          }

          if let json = result as? [String: Any] {
            configRefreshTimestamp = Date()
            if let configurations = json["data"] as? [[String: Any]] {
              self._addConfigurations(configurations)
            }

            for executionBlock in completionBlocks {
              executionBlock(nil)
            }
            completionBlocks.removeAll()
          } else {
            print("Received invalid AEM configuration")
          }

          isLoadingConfiguration = false
        }
      }
    }
  }

  static func _loadCatalogOptimization(
    with invocation: _AEMInvocation,
    contentID: String?,
    block: @escaping () -> Void
  ) {
    networker?.startGraphRequest(
      withGraphPath: "\(appID ?? nullAppID)/aem_conversion_filter",
      parameters: _catalogRequestParameters(invocation.catalogID, contentID: contentID),
      tokenString: nil,
      httpMethod: FBAEMHTTPMethodGET
    ) { result, error in
      dispatchOnQueue(serialQueue) {
        guard error == nil else {
          return
        }

        if self._isContentOptimized(result) {
          block()
        }
      }
    }
  }

  static func _loadRuleMatch(
    _ businessIDs: [String],
    event: String,
    currency potentialCurrency: String?,
    value potentialValue: NSNumber?,
    parameters: [String: Any]?
  ) {
    let content = _AEMUtility.shared.getContent(parameters)
    networker?.startGraphRequest(
      withGraphPath: "\(appID ?? nullAppID)/aem_attribution",
      parameters: _ruleMatchRequestParameters(businessIDs, content: content),
      tokenString: nil,
      httpMethod: FBAEMHTTPMethodGET
    ) { result, error in
      if error != nil || result == nil {
        return
      }

      guard
        let result = result as? [String: Any],
        let data: [Any] = result["data"] as? [Any],
        let json = data.first as? [String: Any]
      else {
        return
      }

      guard let success = json["success"] as? NSNumber else { return }

      if success.boolValue {
        guard let isValidMatch = json["is_valid_match"] as? NSNumber else {
          return
        }

        let matchedBusinessID = json["matched_advertiser_id"] as? String
        let inSegmentValue = json["in_segment_value"] as? NSNumber
        let matchedInvocation = _AEMUtility.shared.getMatchedInvocation(invocations, businessID: matchedBusinessID)
        // Drop the conversion if not a valid match or no matched invocation
        if !isValidMatch.boolValue || matchedInvocation == nil {
          return
        }

        guard let matchedInvocation = matchedInvocation else { return }

        dispatchOnQueue(serialQueue) {
          var currency = potentialCurrency
          var value = potentialValue
          if matchedInvocation.businessID != nil {
            currency = "USD"
            value = inSegmentValue
          }

          self._attributionWithInvocation(
            matchedInvocation,
            event: event,
            currency: currency,
            value: value,
            parameters: parameters,
            isRuleMatchInServer: true
          )
        }
      } else {
        // Fall back to attribution v1 if fails
        dispatchOnQueue(serialQueue) {
          self._attributionV1WithEvent(
            event,
            currency: potentialCurrency,
            value: potentialValue,
            parameters: parameters
          )
        }
      }
    }
  }

  static func _shouldReportConversion(
    inCatalogLevel invocation: _AEMInvocation,
    event: String
  ) -> Bool {
    isConversionFilteringEnabled
      && isCatalogMatchingEnabled
      && invocation.catalogID != nil
      && invocation.isOptimizedEvent(event, configurations: configurations)
  }

  static func _isContentOptimized(_ result: Any?) -> Bool {
    let json = result as? [String: Any]
    let data = json?["data"] as? [Any]
    let catalogData = data?.first as? [String: Any]
    let isOptimized = catalogData?["content_id_belongs_to_catalog_id"] as? NSNumber ?? false
    return isOptimized.boolValue
  }

  static func _requestParameters() -> [String: Any] {
    var params: [String: Any] = [:]
    // append business ids to the request params
    var businessIDs: [String] = []
    for invocation in invocations {
      if let businessID = invocation.businessID {
        businessIDs.append(businessID)
      }
    }

    let businessIDsString = try? BasicUtility.jsonString(for: businessIDs)
    params[BUSINESS_IDS_KEY] = businessIDsString
    params["fields"] = ""
    return params
  }

  static func _catalogRequestParameters(
    _ catalogID: String?,
    contentID: String?
  ) -> [String: Any] {
    [
      FB_CONTENT_IDS_KEY: contentID,
      CATALOG_ID_KEY: catalogID,
    ].compactMapValues { $0 }
  }

  static func _ruleMatchRequestParameters(
    _ businessIDs: [String],
    content: String?
  ) -> [String: Any] {
    let businessIDsString = try? BasicUtility.jsonString(for: businessIDs)

    return [
      BUSINESS_IDS_KEY: businessIDsString,
      FB_CONTENT_DATA_KEY: content,
    ].compactMapValues { $0 }
  }

  static func _isConfigRefreshTimestampValid() -> Bool {
    guard let timestamp = configRefreshTimestamp else {
      return false
    }

    return Date().timeIntervalSince(timestamp) < FB_AEM_CONFIG_TIME_OUT
  }

  static func _shouldRefresh(withIsForced isForced: Bool) -> Bool {
    if isForced {
      return true
    }

    // Refresh if there exists invocation which has business ID
    for invocation in invocations where invocation.businessID != nil {
      return true
    }

    // Refresh if timestamp is expired or cached configuration is empty
    return !_isConfigRefreshTimestampValid() || configurations.isEmpty
  }

  static func _shouldDelayAggregationRequest() -> Bool {
    guard let timestamp = minAggregationRequestTimestamp else {
      return false
    }
    return Date().timeIntervalSince(timestamp) < 0
  }

  // MARK: - Deeplink debugging methods

  static func _sendDebuggingRequest(_ invocation: _AEMInvocation) {
    var params: [[String: Any]] = []
    params.append(_debuggingRequestParameters(invocation))
    if params.isEmpty {
      return
    }

    guard
      let jsonData = try? TypeUtility.data(withJSONObject: params),
      let reports = String(data: jsonData, encoding: .utf8)
    else {
      return
    }

    networker?.startGraphRequest(
      withGraphPath: "\(appID ?? nullAppID)/aem_conversions",
      parameters: ["aem_conversions": reports],
      tokenString: nil,
      httpMethod: FBAEMHTTPMethodPOST
    ) { _, error in
      if let error = error {
        print("Fail to send AEM debugging request with error: \(error)")
      }
    }
  }

  static func _debuggingRequestParameters(_ invocation: _AEMInvocation) -> [String: Any] {
    [
      CAMPAIGN_ID_KEY: invocation.campaignID,
      CONVERSION_DATA_KEY: 0,
      CONSUMPTION_HOUR_KEY: 0,
      TOKEN_KEY: invocation.acsToken,
      DELAY_FLOW_KEY: "server",
    ]
  }

  // MARK: - Background methods

  static func _loadMinAggregationRequestTimestamp() -> Date? {
    dataStore?.fb_object(forKey: FBAEMMINAggregationRequestTimestampKey) as? Date
  }

  static func _updateAggregationRequestTimestamp(_ timeInterval: TimeInterval) {
    let newTimestamp = Date(timeIntervalSince1970: timeInterval)
    minAggregationRequestTimestamp = newTimestamp
    dataStore?.fb_setObject(newTimestamp, forKey: FBAEMMINAggregationRequestTimestampKey)
  }

  static func _loadConfigurations() -> [String: [_AEMConfiguration]] {
    guard let configFile = configFile else { return [:] }

    if let cachedConfiguration = try? NSData(contentsOfFile: configFile, options: .mappedIfSafe) {
      let cache = try? NSKeyedUnarchiver.unarchivedObject(
        ofClasses: [
          NSDictionary.self,
          NSArray.self,
          NSString.self,
          _AEMConfiguration.self,
          _AEMRule.self,
          _AEMEvent.self,
        ],
        from: cachedConfiguration as Data
      ) as? [String: [_AEMConfiguration]]

      if let cache = cache {
        return cache
      }
    }

    return [:]
  }

  private static func _saveConfigurations() {
    let cache = try? NSKeyedArchiver.archivedData(withRootObject: configurations, requiringSecureCoding: false)
    guard
      let cache = cache,
      let configFile = configFile
    else {
      return
    }

    (cache as NSData).write(toFile: configFile, atomically: true)
  }

  static func _addConfigurations(_ configurations: [[String: Any]]) {
    if configurations.isEmpty {
      return
    }

    for configuration in configurations {
      _addConfiguration(_AEMConfiguration(json: configuration))
    }
    _saveConfigurations()
  }

  private static func _addConfiguration(_ configuration: _AEMConfiguration?) {
    guard let configuration = configuration else { return }

    let _configurations = configurations[configuration.mode] ?? []
    // Remove the configuration in the array that has the same "validFrom" and "businessID" as the added configuration
    var newConfigurations: [_AEMConfiguration] = []
    for candidateConfiguration in _configurations {
      if configuration.isSame(
        validFrom: candidateConfiguration.validFrom,
        businessID: candidateConfiguration.businessID
      ) {
        continue
      }

      newConfigurations.append(candidateConfiguration)
    }
    newConfigurations.append(configuration)
    // Sort the configurations via "validFrom"

    if #available(iOS 15.0, *) {
      newConfigurations.sort(using: KeyPathComparator(\.validFrom))
    } else {
      newConfigurations.sort { $0.validFrom < $1.validFrom }
    }
    configurations[configuration.mode] = newConfigurations
  }

  static func _loadReportData() -> [_AEMInvocation] {
    guard let reportFile = reportFile else { return [] }
    if let cachedReportData = try? NSData(contentsOfFile: reportFile, options: .mappedIfSafe) {
      let cache = try? NSKeyedUnarchiver.unarchivedObject(
        ofClasses: [NSArray.self, _AEMInvocation.self],
        from: cachedReportData as Data
      ) as? [_AEMInvocation]

      if let cache = cache {
        return cache
      }
    }
    return []
  }

  static func _saveReportData() {
    let cache = try? NSKeyedArchiver.archivedData(withRootObject: invocations, requiringSecureCoding: false)
    if let cache = cache,
       let reportFile = reportFile {
      (cache as NSData).write(toFile: reportFile, atomically: true)
    }
  }

  static func _sendAggregationRequest() {
    var params: [[String: Any]] = []
    var aggregatedInvocations: [_AEMInvocation] = []
    for invocation in invocations {
      if !invocation.isAggregated {
        params.append(_aggregationRequestParameters(invocation))
        aggregatedInvocations.append(invocation)
      }
    }

    if params.isEmpty {
      return
    }

    let block = {
      guard
        let jsonData = try? TypeUtility.data(withJSONObject: params),
        let reports = String(data: jsonData, encoding: .utf8)
      else {
        return
      }

      networker?.startGraphRequest(
        withGraphPath: "\(appID ?? nullAppID)/aem_conversions",
        parameters: ["aem_conversions": reports],
        tokenString: nil,
        httpMethod: FBAEMHTTPMethodPOST
      ) { _, error in
        if error != nil {
          return
        }

        dispatchOnQueue(serialQueue) {
          for invocation in aggregatedInvocations {
            invocation.isAggregated = true
          }
          _saveReportData()
        }
      }
    }

    if _shouldDelayAggregationRequest() {
      var timestampDelay: TimeInterval = 0
      if let timestamp = minAggregationRequestTimestamp {
        timestampDelay = timestamp.timeIntervalSince1970 - Date().timeIntervalSince1970
      }

      let delay = max(FB_AEM_DELAY, timestampDelay)
      dispatchOnQueue(serialQueue, delay: delay, block: block)
    } else {
      block()
    }

    let minAggregationRequestTimestampDelay = minAggregationRequestTimestamp?.timeIntervalSince1970 ?? 0
    _updateAggregationRequestTimestamp(
      max(
        Date().timeIntervalSince1970 + FB_AEM_DELAY,
        minAggregationRequestTimestampDelay + FB_AEM_DELAY
      )
    )
  }

  static func _aggregationRequestParameters(_ invocation: _AEMInvocation) -> [String: Any] {
    let delay = 24 + arc4random_uniform(24)
    let enableConversionFiltering = invocation.isConversionFilteringEligible && isConversionFilteringEnabled
    return [
      CAMPAIGN_ID_KEY: invocation.campaignID,
      CONVERSION_DATA_KEY: invocation.conversionValue,
      CONSUMPTION_HOUR_KEY: delay,
      TOKEN_KEY: invocation.acsToken,
      DELAY_FLOW_KEY: "server",
      CONFIG_ID_KEY: invocation.acsConfigurationID,
      HMAC_KEY: invocation.getHMAC(delay: Int(delay)),
      BUSINESS_ID_KEY: invocation.businessID,
      IS_CONVERSION_FILTERING_KEY: enableConversionFiltering,
    ].compactMapValues { $0 }
  }

  private static func dispatchOnQueue(
    _ queue: DispatchQueue,
    delay: TimeInterval? = nil,
    block: (() -> Void)?
  ) {
    guard let block = block else { return }

    if queue.label == dispatchQueueLabel {
      if let delay = delay {
        queue.asyncAfter(deadline: .now() + delay, execute: block)
      } else {
        queue.async(execute: block)
      }
    } else { // For tests the queue's label is different
      if delay == nil {
        block()
      }
    }
  }

  static func _clearCache() {
    // step 1: clear aggregated invocations that are outside attribution window
    _clearInvocations()
    // step 2: clear old configurations that are not used anymore and keep the most recent configuration
    _clearConfigurations()
  }

  static func _clearConfigurations() {
    var shouldSaveCache = false
    if !configurations.isEmpty {
      var newConfigurationsDict: [String: [_AEMConfiguration]] = [:]
      for (key, value) in configurations {
        var oldConfigurations: [_AEMConfiguration] = value
        var newConfigurations: [_AEMConfiguration] = []

        // Removes the last of the old default mode configurations and stores it so it can be
        // added to the array-to-save
        var lastConfiguration: _AEMConfiguration?
        if key == "DEFAULT" {
          lastConfiguration = oldConfigurations.last
          oldConfigurations.removeLast()
        }

        for oldConfiguration in oldConfigurations {
          if !_isUsingConfiguration(oldConfiguration, forInvocations: invocations) {
            shouldSaveCache = true
            continue
          }
          newConfigurations.append(oldConfiguration)
        }

        if let lastConfiguration = lastConfiguration {
          newConfigurations.append(lastConfiguration)
        }
        newConfigurationsDict[key] = newConfigurations
      }
      configurations = newConfigurationsDict
    }
    if shouldSaveCache {
      _saveConfigurations()
    }
  }

  private static func _clearInvocations() {
    var isInvocationCacheUpdated = false
    if !invocations.isEmpty {
      var newInvocations: [_AEMInvocation] = []
      for invocation in invocations {
        if invocation.isOutOfWindow(configurations: configurations), invocation.isAggregated {
          isInvocationCacheUpdated = true
          continue
        }
        newInvocations.append(invocation)
      }
      invocations = newInvocations
    }

    if isInvocationCacheUpdated {
      _saveReportData()
    }
  }

  private static func _isUsingConfiguration(
    _ configuration: _AEMConfiguration,
    forInvocations invocations: [_AEMInvocation]
  ) -> Bool {
    for invocation in invocations {
      if configuration.isSame(validFrom: invocation.configurationID, businessID: invocation.businessID) {
        return true
      }
    }
    return false
  }

  // MARK: - Testability

  #if DEBUG

  public static func reset() {
    isAEMReportEnabled = false
    isLoadingConfiguration = false
    isConversionFilteringEnabled = false
    isCatalogMatchingEnabled = false
    isAdvertiserRuleMatchInServerEnabled = false
    completionBlocks = []
    configurations = [:]
    minAggregationRequestTimestamp = nil
    networker = nil
    appID = nil
    reporter = nil
    dataStore = nil
    _clearCache()
  }

  #endif
}

#endif
