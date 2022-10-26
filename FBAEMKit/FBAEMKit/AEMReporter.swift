/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import Foundation

typealias FBAEMReporterBlock = (NSError?) -> Void

@objcMembers
@objc(FBAEMReporter)
public final class AEMReporter: NSObject {
  private enum Keys {
    static let businessID = "advertiser_id"
    static let businessIDs = "advertiser_ids"
    static let fbContentData = "fb_content_data"
    static let alApplinkData = "al_applink_data"
    static let campaignId = "campaign_id"
    static let conversionData = "conversion_data"
    static let consumptionHour = "consumption_hour"
    static let token = "token"
    static let hmac = "hmac"
    static let configId = "config_id"
    static let delayFlow = "delay_flow"
    static let isConversionFiltering = "is_conversion_filtering"
    static let fbContentIds = "fb_content_ids"
    static let catalogId = "catalog_id"
    static let minAggregationRequestTimestamp = "com.facebook.sdk:FBAEMMinAggregationRequestTimestamp"
    static let fields = "fields"
    static let data = "data"
    static let aemConversions = "aem_conversions"
    static let success = "success"
    static let isValidMatch = "is_valid_match"
    static let matchedAdvertiserId = "matched_advertiser_id"
    static let inSegmentValue = "in_segment_value"
    static let contentIdBelongsToCatalogId = "content_id_belongs_to_catalog_id"
  }

  private enum DispatchQueueLabels {
    static let appEvents = "com.facebook.appevents.AEM.FBAEMReporter"
  }

  private enum TimeIntervals {
    static let aemConfigTimeout: TimeInterval = 86400
    static let aemDelay: TimeInterval = 3
  }

  private enum FileNames {
    static let aemReporter = "FBSDKAEMReportData.report"
    static let aemConfig = "FBSDKAEMReportData.config"
  }

  private enum Paths {
    static let aemConversionConfigs = "aem_conversion_configs"
    static let aemConversionFilter = "aem_conversion_filter"
    static let aemAttribution = "aem_attribution"
  }

  private enum HTTPMethods {
    static let GET = "GET"
    static let POST = "POST"
  }

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
  static var serialQueue = DispatchQueue(label: DispatchQueueLabels.appEvents)
  static var reportFile: String?
  private static var configFile: String?
  static var configurations: [String: [AEMConfiguration]] = [:]
  static var invocations: [AEMInvocation] = []
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

    AEMConfiguration.configure(withRuleProvider: AEMAdvertiserRuleFactory())
    reportFile = BasicUtility.persistenceFilePath(FileNames.aemReporter)
    configFile = BasicUtility.persistenceFilePath(FileNames.aemConfig)
    completionBlocks = []

    dispatchOnQueue(serialQueue) {
      minAggregationRequestTimestamp = loadMinAggregationRequestTimestamp()
      configurations = loadConfigurations()
      invocations = loadReportData()
    }

    loadConfiguration(withRefreshForced: false) { error in
      if error != nil {
        return
      }

      sendAggregationRequest()
      clearCache()
    }

    // If developers forget to call configureWithNetworker:appID:
    // or pass nil for networker,
    // we use default networker in FBAEMKit
    if networker == nil {
      let networker = AEMNetworker()
      networker.userAgentSuffix = analyticsAppID
      self.networker = networker
    }

    // If developers forget to call configureWithNetworker:appID:,
    // we will look up app Any in plist file, key is FacebookAppID
    if appID == nil || appID?.isEmpty == true {
      appID = AEMSettings.appID()
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
      sendDebuggingRequest(invocation)
      return
    }

    loadConfiguration(withRefreshForced: true, block: nil)
    appendAndSaveInvocation(invocation)
  }

  static func parseURL(_ url: URL?) -> AEMInvocation? {
    guard let url = url else {
      return nil
    }

    let params = BasicUtility.dictionary(withQueryString: url.query ?? "")
    guard let applinkDataString = params[Keys.alApplinkData] else {
      return nil
    }

    guard let applinkData = try? BasicUtility.object(forJSONString: applinkDataString) as? [AnyHashable: Any] else {
      return nil
    }

    return AEMInvocation(appLinkData: applinkData)
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

    loadConfiguration(withRefreshForced: false) { _ in
      if configurations.isEmpty || invocations.isEmpty {
        return
      }

      let businessIDs = AEMUtility.shared.getBusinessIDsInOrder(invocations)
      if isAdvertiserRuleMatchInServerEnabled,
         let businessID = businessIDs.first,
         !businessID.isEmpty {
        self.loadRuleMatch(businessIDs, event: event, currency: currency, value: value, parameters: parameters)
      } else {
        self.attributionV1WithEvent(event, currency: currency, value: value, parameters: parameters)
      }
    }
  }

  private static func attributionV1WithEvent(
    _ event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?
  ) {
    guard let attributedInvocation = attributedInvocation(
      invocations,
      event: event,
      currency: currency,
      value: value,
      parameters: parameters,
      configurations: configurations
    ) else {
      return
    }

    attributionWithInvocation(
      attributedInvocation,
      event: event,
      currency: currency,
      value: value,
      parameters: parameters,
      isRuleMatchInServer: false
    )
  }

  // swiftlint:disable:next function_parameter_count
  private static func attributionWithInvocation(
    _ invocation: AEMInvocation,
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
    if shouldReportConversion(inCatalogLevel: invocation, event: event) {
      let contentID = AEMUtility.shared.getContentID(parameters)
      loadCatalogOptimization(with: invocation, contentID: contentID) {
        self.updateAttributedInvocation(
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
      updateAttributedInvocation(
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
  private static func updateAttributedInvocation(
    _ invocation: AEMInvocation,
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
      sendAggregationRequest()
    }

    saveReportData()
  }

  // swiftlint:disable:next function_parameter_count
  static func attributedInvocation(
    _ invocations: [AEMInvocation],
    event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?,
    configurations: [String: [AEMConfiguration]]
  ) -> AEMInvocation? {
    var isGeneralInvocationVisited = false
    var attributedInvocation: AEMInvocation?
    for invocation in invocations.reversed() {
      if isDoubleCounting(invocation, event: event) {
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

  static func isDoubleCounting(
    _ invocation: AEMInvocation,
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

  private static func appendAndSaveInvocation(_ invocation: AEMInvocation) {
    dispatchOnQueue(serialQueue) {
      invocations.append(invocation)
      saveReportData()
    }
  }

  static func loadConfiguration(withRefreshForced forced: Bool, block: FBAEMReporterBlock?) {
    dispatchOnQueue(serialQueue) {
      if let block = block {
        completionBlocks.append(block)
      }

      // Executes blocks if there is cache
      if !shouldRefresh(withIsForced: forced) {
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
        withGraphPath: "\(appID ?? nullAppID)/\(Paths.aemConversionConfigs)",
        parameters: requestParameters(),
        tokenString: nil,
        httpMethod: HTTPMethods.GET
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
            if let configurations = json[Keys.data] as? [[String: Any]] {
              self.addConfigurations(configurations)
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

  static func loadCatalogOptimization(
    with invocation: AEMInvocation,
    contentID: String?,
    block: @escaping () -> Void
  ) {
    networker?.startGraphRequest(
      withGraphPath: "\(appID ?? nullAppID)/\(Paths.aemConversionFilter)",
      parameters: catalogRequestParameters(invocation.catalogID, contentID: contentID),
      tokenString: nil,
      httpMethod: HTTPMethods.GET
    ) { result, error in
      dispatchOnQueue(serialQueue) {
        guard error == nil else {
          return
        }

        if self.isContentOptimized(result) {
          block()
        }
      }
    }
  }

  static func loadRuleMatch(
    _ businessIDs: [String],
    event: String,
    currency potentialCurrency: String?,
    value potentialValue: NSNumber?,
    parameters: [String: Any]?
  ) {
    let content = AEMUtility.shared.getContent(parameters)
    networker?.startGraphRequest(
      withGraphPath: "\(appID ?? nullAppID)/\(Paths.aemAttribution)",
      parameters: ruleMatchRequestParameters(businessIDs, content: content),
      tokenString: nil,
      httpMethod: HTTPMethods.GET
    ) { result, error in
      if error != nil || result == nil {
        return
      }

      guard
        let result = result as? [String: Any],
        let data: [Any] = result[Keys.data] as? [Any],
        let json = data.first as? [String: Any]
      else {
        return
      }

      guard let success = json[Keys.success] as? NSNumber else { return }

      if success.boolValue {
        guard let isValidMatch = json[Keys.isValidMatch] as? NSNumber else {
          return
        }

        let matchedBusinessID = json[Keys.matchedAdvertiserId] as? String
        let inSegmentValue = json[Keys.inSegmentValue] as? NSNumber
        let matchedInvocation = AEMUtility.shared.getMatchedInvocation(invocations, businessID: matchedBusinessID)
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

          self.attributionWithInvocation(
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
          self.attributionV1WithEvent(
            event,
            currency: potentialCurrency,
            value: potentialValue,
            parameters: parameters
          )
        }
      }
    }
  }

  static func shouldReportConversion(
    inCatalogLevel invocation: AEMInvocation,
    event: String
  ) -> Bool {
    isConversionFilteringEnabled
      && isCatalogMatchingEnabled
      && invocation.catalogID != nil
      && invocation.isOptimizedEvent(event, configurations: configurations)
  }

  static func isContentOptimized(_ result: Any?) -> Bool {
    let json = result as? [String: Any]
    let data = json?[Keys.data] as? [Any]
    let catalogData = data?.first as? [String: Any]
    let isOptimized = catalogData?[Keys.contentIdBelongsToCatalogId] as? NSNumber ?? false
    return isOptimized.boolValue
  }

  static func requestParameters() -> [String: Any] {
    var params: [String: Any] = [:]
    // append business ids to the request params
    var businessIDs: [String] = []
    for invocation in invocations {
      if let businessID = invocation.businessID {
        businessIDs.append(businessID)
      }
    }

    let businessIDsString = try? BasicUtility.jsonString(for: businessIDs)
    params[Keys.businessIDs] = businessIDsString
    params[Keys.fields] = ""
    return params
  }

  static func catalogRequestParameters(
    _ catalogID: String?,
    contentID: String?
  ) -> [String: Any] {
    [
      Keys.fbContentIds: contentID,
      Keys.catalogId: catalogID,
    ].compactMapValues { $0 }
  }

  static func ruleMatchRequestParameters(
    _ businessIDs: [String],
    content: String?
  ) -> [String: Any] {
    let businessIDsString = try? BasicUtility.jsonString(for: businessIDs)

    return [
      Keys.businessIDs: businessIDsString,
      Keys.fbContentData: content,
    ].compactMapValues { $0 }
  }

  static func isConfigRefreshTimestampValid() -> Bool {
    guard let timestamp = configRefreshTimestamp else {
      return false
    }

    return Date().timeIntervalSince(timestamp) < TimeIntervals.aemConfigTimeout
  }

  static func shouldRefresh(withIsForced isForced: Bool) -> Bool {
    if isForced {
      return true
    }

    // Refresh if there exists invocation which has business ID
    for invocation in invocations where invocation.businessID != nil {
      return true
    }

    // Refresh if timestamp is expired or cached configuration is empty
    return !isConfigRefreshTimestampValid() || configurations.isEmpty
  }

  static func shouldDelayAggregationRequest() -> Bool {
    guard let timestamp = minAggregationRequestTimestamp else {
      return false
    }
    return Date().timeIntervalSince(timestamp) < 0
  }

  // MARK: - Deeplink debugging methods

  static func sendDebuggingRequest(_ invocation: AEMInvocation) {
    var params: [[String: Any]] = []
    params.append(debuggingRequestParameters(invocation))
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
      withGraphPath: "\(appID ?? nullAppID)/\(Keys.aemConversions)",
      parameters: [Keys.aemConversions: reports],
      tokenString: nil,
      httpMethod: HTTPMethods.POST
    ) { _, error in
      if let error = error {
        print("Fail to send AEM debugging request with error: \(error)")
      }
    }
  }

  static func debuggingRequestParameters(_ invocation: AEMInvocation) -> [String: Any] {
    [
      Keys.campaignId: invocation.campaignID,
      Keys.conversionData: 0,
      Keys.consumptionHour: 0,
      Keys.token: invocation.acsToken,
      Keys.delayFlow: "server",
    ]
  }

  // MARK: - Background methods

  static func loadMinAggregationRequestTimestamp() -> Date? {
    dataStore?.fb_object(forKey: Keys.minAggregationRequestTimestamp) as? Date
  }

  static func updateAggregationRequestTimestamp(_ timeInterval: TimeInterval) {
    let newTimestamp = Date(timeIntervalSince1970: timeInterval)
    minAggregationRequestTimestamp = newTimestamp
    dataStore?.fb_setObject(newTimestamp, forKey: Keys.minAggregationRequestTimestamp)
  }

  static func loadConfigurations() -> [String: [AEMConfiguration]] {
    guard let configFile = configFile else { return [:] }

    if let cachedConfiguration = try? NSData(contentsOfFile: configFile, options: .mappedIfSafe) {
      let cache = try? NSKeyedUnarchiver.unarchivedObject(
        ofClasses: [
          NSDictionary.self,
          NSArray.self,
          NSString.self,
          AEMConfiguration.self,
          AEMRule.self,
          AEMEvent.self,
        ],
        from: cachedConfiguration as Data
      ) as? [String: [AEMConfiguration]]

      if let cache = cache {
        return cache
      }
    }

    return [:]
  }

  private static func saveConfigurations() {
    let cache = try? NSKeyedArchiver.archivedData(withRootObject: configurations, requiringSecureCoding: false)
    guard
      let cache = cache,
      let configFile = configFile
    else {
      return
    }

    (cache as NSData).write(toFile: configFile, atomically: true)
  }

  static func addConfigurations(_ configurations: [[String: Any]]) {
    if configurations.isEmpty {
      return
    }

    for configuration in configurations {
      addConfiguration(AEMConfiguration(json: configuration))
    }
    saveConfigurations()
  }

  private static func addConfiguration(_ configuration: AEMConfiguration?) {
    guard let configuration = configuration else { return }

    let configurationsForMode = configurations[configuration.mode] ?? []
    // Remove the configuration in the array that has the same "validFrom" and "businessID" as the added configuration
    var newConfigurations: [AEMConfiguration] = []
    for candidateConfiguration in configurationsForMode {
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

  static func loadReportData() -> [AEMInvocation] {
    guard let reportFile = reportFile else { return [] }
    if let cachedReportData = try? NSData(contentsOfFile: reportFile, options: .mappedIfSafe) {
      let cache = try? NSKeyedUnarchiver.unarchivedObject(
        ofClasses: [NSArray.self, AEMInvocation.self],
        from: cachedReportData as Data
      ) as? [AEMInvocation]

      if let cache = cache {
        return cache
      }
    }
    return []
  }

  static func saveReportData() {
    let cache = try? NSKeyedArchiver.archivedData(withRootObject: invocations, requiringSecureCoding: false)
    if let cache = cache,
       let reportFile = reportFile {
      (cache as NSData).write(toFile: reportFile, atomically: true)
    }
  }

  static func sendAggregationRequest() {
    var params: [[String: Any]] = []
    var aggregatedInvocations: [AEMInvocation] = []
    for invocation in invocations {
      if !invocation.isAggregated {
        params.append(aggregationRequestParameters(invocation))
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
        withGraphPath: "\(appID ?? nullAppID)/\(Keys.aemConversions)",
        parameters: [Keys.aemConversions: reports],
        tokenString: nil,
        httpMethod: HTTPMethods.POST
      ) { _, error in
        if error != nil {
          return
        }

        dispatchOnQueue(serialQueue) {
          for invocation in aggregatedInvocations {
            invocation.isAggregated = true
          }
          saveReportData()
        }
      }
    }

    if shouldDelayAggregationRequest() {
      var timestampDelay: TimeInterval = 0
      if let timestamp = minAggregationRequestTimestamp {
        timestampDelay = timestamp.timeIntervalSince1970 - Date().timeIntervalSince1970
      }

      let delay = max(TimeIntervals.aemDelay, timestampDelay)
      dispatchOnQueue(serialQueue, delay: delay, block: block)
    } else {
      block()
    }

    let minAggregationRequestTimestampDelay = minAggregationRequestTimestamp?.timeIntervalSince1970 ?? 0
    updateAggregationRequestTimestamp(
      max(
        Date().timeIntervalSince1970 + TimeIntervals.aemDelay,
        minAggregationRequestTimestampDelay + TimeIntervals.aemDelay
      )
    )
  }

  static func aggregationRequestParameters(_ invocation: AEMInvocation) -> [String: Any] {
    let delay = 24 + arc4random_uniform(24)
    let enableConversionFiltering = invocation.isConversionFilteringEligible && isConversionFilteringEnabled
    return [
      Keys.campaignId: invocation.campaignID,
      Keys.conversionData: invocation.conversionValue,
      Keys.consumptionHour: delay,
      Keys.token: invocation.acsToken,
      Keys.delayFlow: "server",
      Keys.configId: invocation.acsConfigurationID,
      Keys.hmac: invocation.getHMAC(delay: Int(delay)),
      Keys.businessID: invocation.businessID,
      Keys.isConversionFiltering: enableConversionFiltering,
    ].compactMapValues { $0 }
  }

  private static func dispatchOnQueue(
    _ queue: DispatchQueue,
    delay: TimeInterval? = nil,
    block: (() -> Void)?
  ) {
    guard let block = block else { return }

    if queue.label == DispatchQueueLabels.appEvents {
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

  static func clearCache() {
    // step 1: clear aggregated invocations that are outside attribution window
    clearInvocations()
    // step 2: clear old configurations that are not used anymore and keep the most recent configuration
    clearConfigurations()
  }

  static func clearConfigurations() {
    var shouldSaveCache = false
    if !configurations.isEmpty {
      var newConfigurationsDict: [String: [AEMConfiguration]] = [:]
      for (key, value) in configurations {
        var oldConfigurations: [AEMConfiguration] = value
        var newConfigurations: [AEMConfiguration] = []

        // Removes the last of the old default mode configurations and stores it so it can be
        // added to the array-to-save
        var lastConfiguration: AEMConfiguration?
        if key == "DEFAULT" {
          lastConfiguration = oldConfigurations.last
          oldConfigurations.removeLast()
        }

        for oldConfiguration in oldConfigurations {
          if !isUsingConfiguration(oldConfiguration, forInvocations: invocations) {
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
      saveConfigurations()
    }
  }

  private static func clearInvocations() {
    var isInvocationCacheUpdated = false
    if !invocations.isEmpty {
      var newInvocations: [AEMInvocation] = []
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
      saveReportData()
    }
  }

  private static func isUsingConfiguration(
    _ configuration: AEMConfiguration,
    forInvocations invocations: [AEMInvocation]
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
    clearCache()
  }

  #endif
}
