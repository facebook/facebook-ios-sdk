/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

@available(iOS 15.0, *)
struct IAPTransactionLogger: IAPTransactionLogging {

  static var configuredDependencies: TypeDependencies?
  static var defaultDependencies: TypeDependencies? = .init(
    eventLogger: AppEvents.shared
  )
  let dateFormatter = DateFormatter()
  let maxParameterValueLength = 100

  init() {
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
  }
}

// MARK: - Private Methods

@available(iOS 15.0, *)
extension IAPTransactionLogger {
  private func durationOfSubscriptionPeriod(_ subscriptionPeriod: IAPSubscriptionPeriod?) -> String {
    guard let subscriptionPeriod else {
      return ""
    }
    let unit = subscriptionPeriod.unit.rawValue
    return "P\(subscriptionPeriod.numUnits)\(unit)"
  }

  private func getTruncatedString(_ input: String) -> String {
    guard input.count > maxParameterValueLength else {
      return input
    }
    let endIndex = input.index(input.startIndex, offsetBy: maxParameterValueLength)
    return String(input[..<endIndex])
  }

  private func getParameters(for event: IAPEvent) -> [AppEvents.ParameterName: Any] {
    var parameters: [AppEvents.ParameterName: Any] = [
      .contentID: event.productID,
      .numItems: event.quantity,
      .transactionDate: dateFormatter.string(from: event.transactionDate),
      .productTitle: getTruncatedString(event.productTitle),
      .description: getTruncatedString(event.productDescription),
      .currency: event.currency ?? "",
      .transactionID: event.transactionID,
      .implicitlyLoggedPurchase: "1",
    ]
    if event.isSubscription {
      parameters[.inAppPurchaseType] = IAPType.subscription.rawValue
      parameters[.subscriptionPeriod] = durationOfSubscriptionPeriod(event.subscriptionPeriod)
      parameters[.isStartTrial] = event.isStartTrial ? "1" : "0"
      if event.hasIntroductoryOffer {
        parameters[.hasFreeTrial] = event.hasFreeTrial ? "1" : "0"
        parameters[.trialPeriod] = durationOfSubscriptionPeriod(event.introductoryOfferSubscriptionPeriod)
        parameters[.trialPrice] = event.introductoryOfferPrice?.doubleValue
      }
    } else {
      parameters[.inAppPurchaseType] = IAPType.product.rawValue
    }
    return parameters
  }

  private func logImplicitTransactionEvent(
    eventName: AppEvents.Name,
    valueToSum: Double,
    parameters: [AppEvents.ParameterName: Any]
  ) {
    guard let dependencies = try? Self.getDependencies() else {
      return
    }
    dependencies.eventLogger.logEvent(eventName, valueToSum: valueToSum, parameters: parameters)
    if dependencies.eventLogger.flushBehavior != .explicitOnly {
      dependencies.eventLogger.flush(for: .eagerlyFlushingEvent)
    }
  }
}

// MARK: - Public APIs

@available(iOS 15.0, *)
extension IAPTransactionLogger {
  func logNewTransaction(_ transaction: IAPTransaction) async {
    guard let event = await IAPEventResolver().resolveNewEventFor(iapTransaction: transaction) else {
      return
    }
    let now = Date()
    if event.isSubscription &&
      (now > transaction.transaction.expirationDate ?? now ||
        IAPTransactionCache.shared.contains(transactionID: event.originalTransactionID, eventName: event.eventName) ||
        IAPTransactionCache.shared.contains(transactionID: event.originalTransactionID, eventName: .subscribeRestore)) {
      IAPTransactionCache.shared.addTransaction(transactionID: event.transactionID, eventName: event.eventName)
      return
    }
    if event.eventName == .purchased &&
      IAPTransactionCache.shared.contains(transactionID: event.originalTransactionID) {
      IAPTransactionCache.shared.addTransaction(transactionID: event.transactionID, eventName: event.eventName)
      return
    }
    IAPTransactionCache.shared.addTransaction(transactionID: event.originalTransactionID, eventName: event.eventName)
    let parameters = getParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount.doubleValue,
      parameters: parameters
    )
  }

  func logRestoredTransaction(_ transaction: IAPTransaction) async {
    guard let event = await IAPEventResolver().resolveRestoredEventFor(iapTransaction: transaction) else {
      return
    }
    if IAPTransactionCache.shared.contains(transactionID: event.originalTransactionID, eventName: event.eventName) {
      return
    }
    IAPTransactionCache.shared.addTransaction(transactionID: event.originalTransactionID, eventName: event.eventName)
    let parameters = getParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount.doubleValue,
      parameters: parameters
    )
  }
}

// MARK: - DependentAsObject

@available(iOS 15.0, *)
extension IAPTransactionLogger: DependentAsType {
  struct TypeDependencies {
    var eventLogger: EventLogging
  }
}

// MARK: - In App Purchase Types

enum IAPType: String {
  case subscription = "subs"
  case product = "inapp"
}

// MARK: - Decimal

extension Decimal {
  var doubleValue: Double {
    NSDecimalNumber(decimal: self).doubleValue
  }
}
