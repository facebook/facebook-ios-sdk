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
    eventLogger: AppEvents.shared,
    appStoreReceiptProvider: Bundle(for: ApplicationDelegate.self)
  )
  var resolver: IAPEventResolver?
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
    var appStoreReceiptProvider: _AppStoreReceiptProviding
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

  private func fetchDeviceReceipt() -> String? {
    guard let dependencies = try? Self.getDependencies() else {
      return nil
    }
    guard let receiptURL = dependencies.appStoreReceiptProvider.appStoreReceiptURL,
          let receipt = try? Data(contentsOf: receiptURL) else {
      return nil
    }
    return receipt.base64EncodedString()
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
        parameters[.trialPrice] = event.introductoryOfferPrice?.currencyNumber
      }
    } else {
      parameters[.inAppPurchaseType] = IAPType.product.rawValue
    }
    if event.isClientSideVerifiable {
      parameters[.validationResult] = event.validationResult?.rawValue ?? IAPValidationResult.unverified.rawValue
    }
    if event.shouldAppendReceipt, let receipt = fetchDeviceReceipt() {
      parameters[.iapReceiptData] = receipt
    }
    parameters[.iapClientLibraryVersion] = event.storeKitVersion.rawValue
    parameters[.iapsdkLibraryVersions] = IAPConstants.IAPSDKLibraryVersions
    return parameters
  }

  private func appendInitiatedCheckoutEventForStoreKit2(event: IAPEvent) {
    guard event.storeKitVersion == .version2 else {
      return
    }
    let initiatedCheckoutEvent = IAPEventResolver().getInitiatedCheckoutEventFrom(event: event)
    let initiatedCheckoutParams = getParameters(for: initiatedCheckoutEvent)
    logImplicitTransactionEvent(
      eventName: initiatedCheckoutEvent.eventName,
      valueToSum: initiatedCheckoutEvent.amount,
      parameters: initiatedCheckoutParams
    )
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
    appendInitiatedCheckoutEventForStoreKit2(event: event)
    let newParameters = getParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount,
      parameters: newParameters
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
      valueToSum: event.amount,
      parameters: parameters
    )
  }

  private func logFailedEvent(_ event: IAPEvent) {
    appendInitiatedCheckoutEventForStoreKit2(event: event)
    let parameters = getParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount,
      parameters: parameters
    )
  }

  private func logInitiatedCheckoutEvent(_ event: IAPEvent) {
    let parameters = getParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount,
      parameters: parameters
    )
  }

  private func logImplicitTransactionEvent(
    eventName: AppEvents.Name,
    valueToSum: Decimal,
    parameters: [AppEvents.ParameterName: Any]
  ) {
    guard let dependencies = try? Self.getDependencies() else {
      return
    }
    if IAPDedupeProcessor.shared.isEnabled && IAPDedupeProcessor.shared.shouldDedupeEvent(eventName) {
      IAPDedupeProcessor.shared.processImplicitEvent(
        eventName,
        valueToSum: valueToSum.currencyNumber,
        parameters: parameters,
        accessToken: nil
      )
    } else {
      dependencies.eventLogger.doLogEvent(
        eventName,
        valueToSum: valueToSum.currencyNumber,
        parameters: parameters,
        isImplicitlyLogged: true,
        accessToken: nil,
        operationalParameters: nil
      )
      if dependencies.eventLogger.flushBehavior != .explicitOnly {
        dependencies.eventLogger.flush(for: .eagerlyFlushingEvent)
      }
    }
  }
}

// MARK: - Store Kit 2

@available(iOS 15.0, *)
extension IAPTransactionLogger: IAPFailedTransactionLogging {

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

  func logFailedStoreKit2Purchase(productID: String) {
    Task {
      await logFailedStoreKit2PurchaseAsync(productID: productID)
    }
  }

  private func logFailedStoreKit2PurchaseAsync(productID: String) async {
    guard let event = await IAPEventResolver().resolveFailedEventFor(productID: productID) else {
      return
    }
    logFailedEvent(event)
  }
}

// MARK: - Store Kit 1

extension IAPTransactionLogger: IAPEventResolverDelegate {
  func logTransaction(_ transaction: SKPaymentTransaction) {
    resolver = IAPEventResolver()
    resolver?.delegate = self
    resolver?.resolveEventFor(transaction: transaction)
  }

  func didResolveNew(event: IAPEvent) {
    logNewEvent(event)
    resolver = nil
  }

  func didResolveRestored(event: IAPEvent) {
    logRestoredEvent(event)
    resolver = nil
  }

  func didResolveFailed(event: IAPEvent) {
    logFailedEvent(event)
    resolver = nil
  }

  func didResolveInitiatedCheckout(event: IAPEvent) {
    logInitiatedCheckoutEvent(event)
    resolver = nil
  }
}

// MARK: - In App Purchase Types

enum IAPType: String {
  case subscription = "subs"
  case product = "inapp"
}

// MARK: - Decimal

extension Decimal {
  var currencyNumber: NSDecimalNumber {
    var decimalNumber = NSDecimalNumber(decimal: self)
    let behavior = NSDecimalNumberHandler(
      roundingMode: .plain,
      scale: 3,
      raiseOnExactness: false,
      raiseOnOverflow: false,
      raiseOnUnderflow: false,
      raiseOnDivideByZero: false
    )
    decimalNumber = decimalNumber.rounding(accordingToBehavior: behavior)
    return decimalNumber
  }
}
