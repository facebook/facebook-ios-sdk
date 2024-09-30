/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

final class IAPTransactionLogger: NSObject, IAPTransactionLogging {

  static var configuredDependencies: TypeDependencies?
  static var defaultDependencies: TypeDependencies? = .init(
    eventLogger: AppEvents.shared
  )
  let dateFormatter = DateFormatter()
  let maxParameterValueLength = 100

  override init() {
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = IAPConstants.transactionDateFormat
  }
}

// MARK: - DependentAsObject

extension IAPTransactionLogger: DependentAsType {
  struct TypeDependencies {
    var eventLogger: EventLogging
  }
}

// MARK: - Private Methods

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
    let transactionDate = event.transactionDate.map { dateFormatter.string(from: $0) } ?? ""
    var parameters: [AppEvents.ParameterName: Any] = [
      .contentID: event.productID,
      .numItems: event.quantity,
      .transactionDate: transactionDate,
      .currency: event.currency ?? "",
      .implicitlyLoggedPurchase: "1",
    ]
    if let productTitle = event.productTitle {
      parameters[.productTitle] = getTruncatedString(productTitle)
    }
    if let productDescription = event.productDescription {
      parameters[.description] = getTruncatedString(productDescription)
    }
    if let transactionID = event.transactionID {
      parameters[.transactionID] = transactionID
    }
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

  private func logNewEvent(_ event: IAPEvent) {
    if event.isSubscription &&
      (IAPTransactionCache.shared.contains(transactionID: event.originalTransactionID, eventName: event.eventName) ||
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

  private func logRestoredEvent(_ event: IAPEvent) {
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

  private func logInitiatedCheckoutOrFailedEvent(_ event: IAPEvent) {
    let parameters = getParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount.doubleValue,
      parameters: parameters
    )
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

// MARK: - Store Kit 2

@available(iOS 15.0, *)
extension IAPTransactionLogger {
  func logNewTransaction(_ transaction: IAPTransaction) async {
    guard let event = await IAPEventResolver().resolveNewEventFor(iapTransaction: transaction) else {
      return
    }
    logNewEvent(event)
  }

  func logRestoredTransaction(_ transaction: IAPTransaction) async {
    guard let event = await IAPEventResolver().resolveRestoredEventFor(iapTransaction: transaction) else {
      return
    }
    logRestoredEvent(event)
  }
}

// MARK: - Store Kit 1

extension IAPTransactionLogger: IAPEventResolverDelegate {
  func logTransaction(_ transaction: SKPaymentTransaction) {
    let resolver = IAPEventResolver()
    resolver.delegate = self
    resolver.resolveEventFor(transaction: transaction)
  }

  func didResolveNew(event: IAPEvent) {
    logNewEvent(event)
  }

  func didResolveRestored(event: IAPEvent) {
    logRestoredEvent(event)
  }

  func didResolveFailed(event: IAPEvent) {
    logInitiatedCheckoutOrFailedEvent(event)
  }

  func didResolveInitiatedCheckout(event: IAPEvent) {
    logInitiatedCheckoutOrFailedEvent(event)
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
