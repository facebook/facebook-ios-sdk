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

  private func getCustomParameters(for event: IAPEvent) -> [AppEvents.ParameterName: Any] {
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
    return parameters
  }

  private func getOperationalParameters(for event: IAPEvent) -> [AppOperationalDataType: [String: Any]] {
    var iapParameters = [String: Any]()
    let transactionDate = event.transactionDate.map { dateFormatter.string(from: $0) } ?? ""
    let originalTransactionDate = event.originalTransactionDate.map { dateFormatter.string(from: $0) } ?? ""
    let consumablesInPurchaseHistory =
      Bundle.main.fb_object(forInfoDictionaryKey: IAPConstants.consumablesInPurchaseHistoryKey) as? Bool ?? false
    iapParameters = [
      AppEvents.ParameterName.contentID.rawValue: event.productID,
      AppEvents.ParameterName.transactionDate.rawValue: transactionDate,
      AppEvents.ParameterName.iapsdkLibraryVersions.rawValue: IAPConstants.IAPSDKLibraryVersions,
      AppEvents.ParameterName.iapClientLibraryVersion.rawValue: event.storeKitVersion.rawValue,
      AppEvents.ParameterName.consumablesInPurchaseHistory.rawValue: consumablesInPurchaseHistory ? "1" : "0",
    ]
    if let transactionID = event.transactionID {
      iapParameters[AppEvents.ParameterName.transactionID.rawValue] = transactionID
    }
    if let originalTransactionID = event.originalTransactionID {
      iapParameters[AppEvents.ParameterName.originalTransactionID.rawValue] = originalTransactionID
    }
    iapParameters[AppEvents.ParameterName.originalTransactionDate.rawValue] = originalTransactionDate
    if event.isClientSideVerifiable {
      let validationResult = event.validationResult?.rawValue ?? IAPValidationResult.unverified.rawValue
      iapParameters[AppEvents.ParameterName.validationResult.rawValue] = validationResult
    }
    if event.isSubscription {
      iapParameters[AppEvents.ParameterName.isStartTrial.rawValue] = event.isStartTrial ? "1" : "0"
      let subscriptionPeriod = durationOfSubscriptionPeriod(event.subscriptionPeriod)
      iapParameters[AppEvents.ParameterName.subscriptionPeriod.rawValue] = subscriptionPeriod
      iapParameters[AppEvents.ParameterName.inAppPurchaseType.rawValue] = IAPType.subscription.rawValue
    } else {
      iapParameters[AppEvents.ParameterName.inAppPurchaseType.rawValue] = IAPType.product.rawValue
    }
    if let productType = event.productType {
      iapParameters[AppEvents.ParameterName.productClassification.rawValue] = productType.rawValue
    }
    let operationalParameters = [
      AppOperationalDataType.iapParameters: iapParameters,
    ]
    return operationalParameters
  }

  private func appendInitiatedCheckoutEventForStoreKit2(event: IAPEvent) {
    guard event.storeKitVersion == .version2 else {
      return
    }
    let initiatedCheckoutEvent = IAPEventResolver().getInitiatedCheckoutEventFrom(event: event)
    let initiatedCheckoutParams = getCustomParameters(for: initiatedCheckoutEvent)
    let initiatedCheckoutOperationalParams = getOperationalParameters(for: initiatedCheckoutEvent)
    logImplicitTransactionEvent(
      eventName: initiatedCheckoutEvent.eventName,
      valueToSum: initiatedCheckoutEvent.amount,
      parameters: initiatedCheckoutParams,
      operationalParameters: initiatedCheckoutOperationalParams
    )
  }

  private func logNewEvent(_ event: IAPEvent) {
    if event.isSubscription &&
      (
        IAPTransactionCache.shared.contains(
          transactionID: event.originalTransactionID,
          eventName: event.eventName,
          productID: event.productID
        ) ||
          IAPTransactionCache.shared.contains(
            transactionID: event.originalTransactionID,
            eventName: .subscribeRestore,
            productID: event.productID
          )
      ) {
      IAPTransactionCache.shared.addTransaction(
        transactionID: event.transactionID,
        eventName: event.eventName,
        productID: event.productID
      )
      return
    }
    if event.eventName == .purchased &&
      IAPTransactionCache.shared.contains(
        transactionID: event.originalTransactionID,
        productID: event.productID
      ) {
      IAPTransactionCache.shared.addTransaction(
        transactionID: event.transactionID,
        eventName: event.eventName,
        productID: event.productID
      )
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: event.originalTransactionID,
      eventName: event.eventName,
      productID: event.productID
    )
    appendInitiatedCheckoutEventForStoreKit2(event: event)
    let newParameters = getCustomParameters(for: event)
    let newOperationalParameters = getOperationalParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount,
      parameters: newParameters,
      operationalParameters: newOperationalParameters
    )
  }

  private func logRestoredEvent(_ event: IAPEvent) {
    if IAPTransactionCache.shared.contains(
      transactionID: event.originalTransactionID,
      productID: event.productID
    ) {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: event.originalTransactionID,
      eventName: event.eventName,
      productID: event.productID
    )
    if event.productType == .nonRenewable || event.productType == .consumable {
      return
    }
    let parameters = getCustomParameters(for: event)
    let operationalParameters = getOperationalParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount,
      parameters: parameters,
      operationalParameters: operationalParameters
    )
  }

  private func logFailedEvent(_ event: IAPEvent) {
    appendInitiatedCheckoutEventForStoreKit2(event: event)
    let parameters = getCustomParameters(for: event)
    let operationalParameters = getOperationalParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount,
      parameters: parameters,
      operationalParameters: operationalParameters
    )
  }

  private func logInitiatedCheckoutEvent(_ event: IAPEvent) {
    let parameters = getCustomParameters(for: event)
    let operationalParameters = getOperationalParameters(for: event)
    logImplicitTransactionEvent(
      eventName: event.eventName,
      valueToSum: event.amount,
      parameters: parameters,
      operationalParameters: operationalParameters
    )
  }

  private func logImplicitTransactionEvent(
    eventName: AppEvents.Name,
    valueToSum: Decimal,
    parameters: [AppEvents.ParameterName: Any],
    operationalParameters: [AppOperationalDataType: [String: Any]]?
  ) {
    guard let dependencies = try? Self.getDependencies() else {
      return
    }
    if IAPDedupeProcessor.shared.isEnabled &&
      IAPDedupeProcessor.shared.shouldDedupeEvent(
        eventName,
        valueToSum: valueToSum.currencyNumber,
        parameters: parameters
      ) {
      IAPDedupeProcessor.shared.processImplicitEvent(
        eventName,
        valueToSum: valueToSum.currencyNumber,
        parameters: parameters,
        accessToken: nil,
        operationalParameters: operationalParameters
      )
    } else {
      dependencies.eventLogger.doLogEvent(
        eventName,
        valueToSum: valueToSum.currencyNumber,
        parameters: parameters,
        isImplicitlyLogged: true,
        accessToken: nil,
        operationalParameters: operationalParameters
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
