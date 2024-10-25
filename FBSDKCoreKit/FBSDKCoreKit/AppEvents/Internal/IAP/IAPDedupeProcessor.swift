/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class IAPDedupeProcessor: _IAPDedupeProcessing {
  private(set) var isEnabled = false
  private var manuallyLoggedEvents: [DedupableEvent] = []
  private var implicitlyLoggedEvents: [DedupableEvent] = []
  private var timer: Timer?

  private var synchronizedManualEvents: [DedupableEvent] {
    var events: [DedupableEvent] = []
    synchronized(self) {
      events = manuallyLoggedEvents
    }
    return events
  }

  private var synchronizedImplicitEvents: [DedupableEvent] {
    var events: [DedupableEvent] = []
    synchronized(self) {
      events = implicitlyLoggedEvents
    }
    return events
  }

  private static let dateFormatter = DateFormatter()
  private static var valueToSumKey = "_valueToSum"
  static var configuredDependencies: TypeDependencies?
  static var defaultDependencies: TypeDependencies? = .init(
    eventLogger: AppEvents.shared,
    appEventsConfigurationProvider: _AppEventsConfigurationManager.shared
  )

  private static var dedupWindow: TimeInterval {
    guard let dependencies = try? Self.getDependencies() else {
      return IAPConstants.defaultIAPDedupeWindow
    }
    let configuredWindow =
      dependencies.appEventsConfigurationProvider.cachedAppEventsConfiguration.iapManualAndAutoLogDedupWindow
    return TimeInterval(configuredWindow / 1000)
  }

  static let shared = IAPDedupeProcessor()

  private init() {
    Self.dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    Self.dateFormatter.dateFormat = IAPConstants.transactionDateFormat
  }
}

// MARK: - DependentAsObject

extension IAPDedupeProcessor: DependentAsType {
  struct TypeDependencies {
    var eventLogger: EventLogging
    var appEventsConfigurationProvider: _AppEventsConfigurationProviding
  }
}

// MARK: - Public APIs

extension IAPDedupeProcessor {
  func enable() {
    guard !isEnabled else {
      return
    }
    synchronized(self) {
      isEnabled = true
    }
  }

  func disable() {
    guard isEnabled else {
      return
    }
    synchronized(self) {
      isEnabled = false
    }
  }

  func shouldDedupeEvent(_ eventName: AppEvents.Name) -> Bool {
    IAPConstants.dedupableEvents.contains(eventName)
  }

  func processManualEvent(
    _ eventName: AppEvents.Name,
    valueToSum: NSNumber?,
    parameters: [AppEvents.ParameterName: Any]?,
    accessToken: AccessToken?
  ) {
    var manualParams = parameters
    if manualParams == nil {
      manualParams = [
        AppEvents.ParameterName.logTime: Int(_AppEventsUtility.shared.unixTimeNow),
      ]
    } else {
      if let keys = manualParams?.keys, !keys.contains(AppEvents.ParameterName.logTime) {
        manualParams?[AppEvents.ParameterName.logTime] = Int(_AppEventsUtility.shared.unixTimeNow)
      }
    }
    if #available(iOS 15.0, *) {
      Task {
        await IAPTransactionObserver.shared.observeNewTransactions()
      }
    }
    let event = DedupableEvent(
      eventName: eventName,
      valueToSum: valueToSum,
      parameters: manualParams?.stringKeys,
      isImplicitEvent: false,
      accessToken: accessToken
    )
    synchronized(self) {
      manuallyLoggedEvents.append(event)
      if timer == nil {
        DispatchQueue.main.async {
          self.timer = Timer.scheduledTimer(withTimeInterval: Self.dedupWindow, repeats: false) { _ in
            self.performDedup()
          }
        }
      }
    }
  }

  func processImplicitEvent(
    _ eventName: AppEvents.Name,
    valueToSum: NSNumber?,
    parameters: [AppEvents.ParameterName: Any]?,
    accessToken: AccessToken?
  ) {
    let event = DedupableEvent(
      eventName: eventName,
      valueToSum: valueToSum,
      parameters: parameters?.stringKeys,
      isImplicitEvent: true,
      accessToken: accessToken
    )
    synchronized(self) {
      implicitlyLoggedEvents.append(event)
      DispatchQueue.main.async {
        self.timer = Timer.scheduledTimer(withTimeInterval: Self.dedupWindow, repeats: false) { _ in
          self.performDedup()
        }
      }
    }
  }

  func performDedup() {
    timer?.invalidate()
    timer = nil
    guard let dependencies = try? Self.getDependencies() else {
      return
    }
    var manualEvents = synchronizedManualEvents
    manuallyLoggedEvents = []
    var implicitEvents = synchronizedImplicitEvents
    implicitlyLoggedEvents = []
    let productionDedupConfig =
      dependencies.appEventsConfigurationProvider.cachedAppEventsConfiguration.iapProdDedupConfiguration
    let testDedupConfig =
      dependencies.appEventsConfigurationProvider.cachedAppEventsConfiguration.iapTestDedupConfiguration
    for (implicitIndex, var implicitEvent) in implicitEvents.enumerated() {
      for (manualIndex, var manualEvent) in manualEvents.enumerated() {
        if !implicitEvent.hasBeenProdDeduped,
           !manualEvent.hasBeenProdDeduped,
           let dedupKey = Self.areDuplicates(
             implicitEvent: implicitEvent,
             manualEvent: manualEvent,
             dedupConfiguration: productionDedupConfig
           ) {
          manualEvent = injectDedupeParameters(
            nonDedupedEvent: implicitEvent,
            dedupedEvent: manualEvent,
            prodDedupeKey: dedupKey,
            shouldOverrideNonDedupedEventTime: true
          )
          manualEvent.hasBeenProdDeduped = true
          implicitEvent.hasBeenProdDeduped = true
        }
        if !implicitEvent.hasBeenTestDeduped,
           !manualEvent.hasBeenTestDeduped,
           let dedupKey = Self.areDuplicates(
             implicitEvent: implicitEvent,
             manualEvent: manualEvent,
             dedupConfiguration: testDedupConfig
           ) {
          manualEvent = injectDedupeParameters(
            nonDedupedEvent: implicitEvent,
            dedupedEvent: manualEvent,
            testDedupKey: dedupKey
          )
          manualEvent.hasBeenTestDeduped = true
          implicitEvent.hasBeenTestDeduped = true
        }
        manualEvents[manualIndex] = manualEvent
      }
      implicitEvents[implicitIndex] = implicitEvent
    }
    for implicitEvent in implicitEvents {
      dependencies.eventLogger.doLogEvent(
        implicitEvent.eventName,
        valueToSum: implicitEvent.valueToSum,
        parameters: implicitEvent.parameters?.appEventParameterKeys,
        isImplicitlyLogged: implicitEvent.isImplicitEvent,
        accessToken: implicitEvent.accessToken
      )
    }
    for manualEvent in manualEvents {
      dependencies.eventLogger.doLogEvent(
        manualEvent.eventName,
        valueToSum: manualEvent.valueToSum,
        parameters: manualEvent.parameters?.appEventParameterKeys,
        isImplicitlyLogged: manualEvent.isImplicitEvent,
        accessToken: manualEvent.accessToken
      )
    }
    if dependencies.eventLogger.flushBehavior != .explicitOnly {
      dependencies.eventLogger.flush(for: .eagerlyFlushingEvent)
    }
  }

  class func areDuplicates(
    implicitEvent: DedupableEvent,
    manualEvent: DedupableEvent,
    dedupConfiguration: [String: [String]]
  ) -> String? {
    guard implicitEvent.eventName == manualEvent.eventName,
          areWithinDedupWindow(implicitEvent: implicitEvent, manualEvent: manualEvent),
          valueCheck(implicitEvent: implicitEvent, manualEvent: manualEvent, dedupConfiguration: dedupConfiguration),
          currencyCheck(implicitEvent: implicitEvent, manualEvent: manualEvent, dedupConfiguration: dedupConfiguration)
    else {
      return nil
    }
    guard let dedupKey = iapKeyCheck(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: dedupConfiguration
    ) else {
      return nil
    }
    return dedupKey
  }
}

extension IAPDedupeProcessor {
  private func injectDedupeParameters(
    nonDedupedEvent: DedupableEvent,
    dedupedEvent: DedupableEvent,
    prodDedupeKey: String? = nil,
    testDedupKey: String? = nil,
    shouldOverrideNonDedupedEventTime: Bool = false
  ) -> DedupableEvent {
    var result = dedupedEvent
    if result.parameters == nil {
      result.parameters = [String: Any]()
    }
    if let prodDedupeKey {
      result.parameters?["fb_iap_actual_dedup_result"] = "1"
      result.parameters?["fb_iap_actual_dedup_key_used"] = prodDedupeKey
    }
    if let testDedupKey {
      result.parameters?["fb_iap_test_dedup_result"] = "1"
      result.parameters?["fb_iap_test_dedup_key_used"] = testDedupKey
    }
    if shouldOverrideNonDedupedEventTime || dedupedEvent.parameters?["fb_iap_non_deduped_event_time"] == nil {
      result.parameters?["fb_iap_non_deduped_event_time"] =
        Self.getUnixTimeStampFromTransactionDate(implicitEvent: nonDedupedEvent)
    }
    return result
  }

  private class func getUnixTimeStampFromTransactionDate(implicitEvent: DedupableEvent) -> TimeInterval? {
    guard let implicitTransactionDate =
      implicitEvent.parameters?[AppEvents.ParameterName.transactionDate.rawValue] as? String else {
      return nil
    }
    guard let date = dateFormatter.date(from: implicitTransactionDate) else {
      return nil
    }
    return _AppEventsUtility.shared.convert(toUnixTime: date)
  }

  private class func areWithinDedupWindow(
    implicitEvent: DedupableEvent,
    manualEvent: DedupableEvent
  ) -> Bool {
    var manualLogTime: Int?
    if let manualLogTimeInt = manualEvent.parameters?[AppEvents.ParameterName.logTime.rawValue] as? Int {
      manualLogTime = manualLogTimeInt
    } else if let manualLogTimeString = manualEvent.parameters?[AppEvents.ParameterName.logTime.rawValue] as? String {
      manualLogTime = Int(manualLogTimeString)
    } else if let manualLogTimeDouble = manualEvent.parameters?[AppEvents.ParameterName.logTime.rawValue] as? Double {
      manualLogTime = Int(manualLogTimeDouble)
    }
    guard let manualLogTime else {
      return false
    }
    let manualLogTimeInterval = TimeInterval(manualLogTime)
    guard let implicitTransactionTime = getUnixTimeStampFromTransactionDate(implicitEvent: implicitEvent) else {
      return false
    }
    let logDifference = abs(manualLogTimeInterval - implicitTransactionTime)
    return logDifference <= dedupWindow
  }

  private class func valueCheck(
    implicitEvent: DedupableEvent,
    manualEvent: DedupableEvent,
    dedupConfiguration: [String: [String]]
  ) -> Bool {
    guard let implicitValue = implicitEvent.valueToSum else {
      return false
    }
    let dedupValueKeys = dedupConfiguration[Self.valueToSumKey] ?? [Self.valueToSumKey]
    for dedupKey in dedupValueKeys {
      if dedupKey == valueToSumKey, implicitValue == manualEvent.valueToSum {
        return true
      }
      if implicitValue == manualEvent.parameters?[dedupKey] as? NSNumber {
        return true
      }
    }
    return false
  }

  private class func currencyCheck(
    implicitEvent: DedupableEvent,
    manualEvent: DedupableEvent,
    dedupConfiguration: [String: [String]]
  ) -> Bool {
    guard let implicitCurrency = implicitEvent.parameters?[AppEvents.ParameterName.currency.rawValue] as? String else {
      return false
    }
    let dedupCurrencyKeys = dedupConfiguration[AppEvents.ParameterName.currency.rawValue] ??
      [AppEvents.ParameterName.currency.rawValue]
    for dedupKey in dedupCurrencyKeys {
      if let manualCurrency = manualEvent.parameters?[dedupKey] as? String, implicitCurrency == manualCurrency {
        return true
      }
    }
    return false
  }

  private class func iapKeyCheck(
    implicitEvent: DedupableEvent,
    manualEvent: DedupableEvent,
    dedupConfiguration: [String: [String]]
  ) -> String? {
    let iapKeys = dedupConfiguration.keys
    for iapKey in iapKeys {
      if iapKey == valueToSumKey || iapKey == AppEvents.ParameterName.currency.rawValue {
        continue
      }
      let dedupKeys = dedupConfiguration[iapKey] ?? [iapKey]
      for dedupKey in dedupKeys {
        guard let implicitParam = implicitEvent.parameters?[iapKey],
              let manualParam = manualEvent.parameters?[dedupKey] else {
          continue
        }
        let implicitValue = String(describing: implicitParam)
        let manualValue = String(describing: manualParam)
        if !implicitValue.isEmpty, !manualValue.isEmpty, implicitValue == manualValue {
          return dedupKey
        }
      }
    }
    return nil
  }
}

struct DedupableEvent {
  var eventName: AppEvents.Name
  var valueToSum: NSNumber?
  var parameters: [String: Any]?
  var isImplicitEvent: Bool
  var accessToken: AccessToken?
  var hasBeenProdDeduped = false
  var hasBeenTestDeduped = false
}

extension [AppEvents.ParameterName: Any] {
  var stringKeys: [String: Any] {
    self.reduce(into: [String: Any]()) { result, pair in
      result[pair.key.rawValue] = pair.value
    }
  }
}

extension [String: Any] {
  var appEventParameterKeys: [AppEvents.ParameterName: Any] {
    self.reduce(into: [AppEvents.ParameterName: Any]()) { result, pair in
      result[AppEvents.ParameterName(rawValue: pair.key)] = pair.value
    }
  }
}
