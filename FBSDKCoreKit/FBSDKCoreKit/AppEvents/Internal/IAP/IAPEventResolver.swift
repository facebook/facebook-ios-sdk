/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

protocol IAPEventResolverDelegate: AnyObject {
  func didResolveNew(event: IAPEvent)
  func didResolveRestored(event: IAPEvent)
  func didResolveFailed(event: IAPEvent)
  func didResolveInitiatedCheckout(event: IAPEvent)
}

final class IAPEventResolver: NSObject {
  static var configuredDependencies: TypeDependencies?
  static var defaultDependencies: TypeDependencies? = .init(
    gateKeeperManager: _GateKeeperManager.self,
    iapSKProductRequestFactory: IAPSKProductsRequestFactory()
  )

  weak var delegate: IAPEventResolverDelegate?

  private var isSubscriptionsEnabled: Bool {
    guard let dependencies = try? Self.getDependencies() else {
      return false
    }
    return dependencies.gateKeeperManager.bool(
      forKey: IAPConstants.gateKeeperAppEventsIfAutoLogSubs,
      defaultValue: false
    )
  }
}

// MARK: - DependentAsObject

extension IAPEventResolver: DependentAsType {
  struct TypeDependencies {
    var gateKeeperManager: _GateKeeperManaging.Type
    var iapSKProductRequestFactory: IAPSKProductsRequestCreating
  }
}

// MARK: - Store Kit 2

@available(iOS 15.0, *)
extension IAPEventResolver {
  func resolveNewEventFor(iapTransaction: IAPTransaction) async -> IAPEvent? {
    var eventName: AppEvents.Name = .purchased
    if iapTransaction.transaction.isSubscription, isSubscriptionsEnabled {
      eventName = resolveNewSubscriptionEventName(transaction: iapTransaction.transaction)
    }
    return await resolveEventFor(iapTransaction: iapTransaction, eventName: eventName)
  }

  func resolveRestoredEventFor(iapTransaction: IAPTransaction) async -> IAPEvent? {
    var eventName: AppEvents.Name = .purchaseRestored
    if iapTransaction.transaction.isSubscription, isSubscriptionsEnabled {
      eventName = .subscribeRestore
    }
    return await resolveEventFor(iapTransaction: iapTransaction, eventName: eventName)
  }

  private func isStartTrial(transaction: Transaction) -> Bool {
    var isFreeTrial = false
    if #available(iOS 17.2, *) {
      isFreeTrial = transaction.offer?.paymentMode == .freeTrial
    } else {
      isFreeTrial = transaction.offerPaymentModeStringRepresentation == IAPConstants.storeKitFreeTrialPaymentModeString
    }
    return isFreeTrial
  }

  private func resolveNewSubscriptionEventName(transaction: Transaction) -> AppEvents.Name {
    let isFreeTrial = isStartTrial(transaction: transaction)
    return isFreeTrial ? .startTrial : .subscribe
  }

  private func getProductFor(iapTransaction: IAPTransaction) async -> Product? {
    guard let products = try? await Product.products(for: [iapTransaction.transaction.productID]),
          let product = products.first else {
      return nil
    }
    return product
  }

  private func resolveEventFor(iapTransaction: IAPTransaction, eventName: AppEvents.Name) async -> IAPEvent? {
    guard let product = await getProductFor(iapTransaction: iapTransaction) else {
      return nil
    }
    let transaction = iapTransaction.transaction
    var currency = transaction.currencyCode
    if #available(iOS 16.0, *) {
      currency = transaction.currency?.identifier
    }
    let introOffer = product.subscription?.introductoryOffer
    let hasIntroductoryOffer = introOffer != nil
    let hasFreeTrial = introOffer?.paymentMode == .freeTrial
    return IAPEvent(
      eventName: eventName,
      productID: transaction.productID,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: transaction.price ?? 0.0,
      quantity: transaction.purchasedQuantity,
      currency: currency,
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: transaction.purchaseDate,
      originalTransactionDate: transaction.originalPurchaseDate,
      isVerified: iapTransaction.isVerified,
      isSubscription: iapTransaction.transaction.isSubscription,
      subscriptionPeriod: product.subscription?.subscriptionPeriod.iapSubscriptionPeriod,
      isStartTrial: isStartTrial(transaction: iapTransaction.transaction),
      hasIntroductoryOffer: hasIntroductoryOffer,
      hasFreeTrial: hasFreeTrial,
      introductoryOfferSubscriptionPeriod: introOffer?.period.iapSubscriptionPeriod,
      introductoryOfferPrice: introOffer?.price,
      storeKitVersion: .version2
    )
  }
}

// MARK: - Store Kit 1

extension IAPEventResolver {
  private func isStartTrial(_ transaction: SKPaymentTransaction, ofProduct product: SKProduct?) -> Bool {
    guard let product else {
      return false
    }
    if #available(iOS 12.2, *) {
      if let paymentDiscount = transaction.payment.paymentDiscount {
        let discounts = product.discounts
        for discount in discounts where discount.paymentMode == .freeTrial &&
          paymentDiscount.identifier == discount.identifier {
          return true
        }
      }
    }
    if product.introductoryPrice?.paymentMode == .freeTrial,
       transaction.original?.transactionIdentifier == nil {
      return true
    }
    return false
  }

  private func resolveSubscriptionEventNameFor(
    transaction: SKPaymentTransaction,
    product: SKProduct?
  ) -> AppEvents.Name? {
    switch transaction.transactionState {
    case .purchasing: return .subscribeInitiatedCheckout
    case .purchased: return isStartTrial(transaction, ofProduct: product) ? .startTrial : .subscribe
    case .failed: return .subscribeFailed
    case .restored: return .subscribeRestore
    case .deferred: return nil
    @unknown default: return nil
    }
  }

  private func resolvePurchaseEventNameFor(transaction: SKPaymentTransaction) -> AppEvents.Name? {
    switch transaction.transactionState {
    case .purchasing: return .initiatedCheckout
    case .purchased: return .purchased
    case .failed: return .purchaseFailed
    case .restored: return .purchaseRestored
    case .deferred: return nil
    @unknown default: return nil
    }
  }

  private func resolveEventNameFor(transaction: SKPaymentTransaction, product: SKProduct?) -> AppEvents.Name? {
    if product?.isSubscription == true, isSubscriptionsEnabled {
      return resolveSubscriptionEventNameFor(transaction: transaction, product: product)
    }
    return resolvePurchaseEventNameFor(transaction: transaction)
  }

  private func didResolve(event: IAPEvent, for transaction: SKPaymentTransaction) {
    switch transaction.transactionState {
    case .purchasing: delegate?.didResolveInitiatedCheckout(event: event)
    case .purchased: delegate?.didResolveNew(event: event)
    case .failed: delegate?.didResolveFailed(event: event)
    case .restored: delegate?.didResolveRestored(event: event)
    case .deferred: return
    @unknown default: return
    }
  }

  private func resolveEventFor(transaction: SKPaymentTransaction, product: SKProduct?) {
    guard let eventName = resolveEventNameFor(transaction: transaction, product: product) else {
      return
    }
    let isStartTrial = isStartTrial(transaction, ofProduct: product)
    var amount = 0.0
    if let product, !isStartTrial {
      amount = Double(transaction.payment.quantity) * product.price.doubleValue
    }
    let hasIntroductoryOffer = product?.introductoryPrice != nil
    let hasFreeTrial = product?.introductoryPrice?.paymentMode == .freeTrial
    let event = IAPEvent(
      eventName: eventName,
      productID: transaction.payment.productIdentifier,
      productTitle: product?.localizedTitle,
      productDescription: product?.localizedDescription,
      amount: Decimal(amount),
      quantity: transaction.payment.quantity,
      currency: product?.priceLocale.currencyCode,
      transactionID: transaction.transactionIdentifier,
      originalTransactionID: transaction.original?.transactionIdentifier ?? transaction.transactionIdentifier,
      transactionDate: transaction.transactionDate,
      originalTransactionDate: transaction.original?.transactionDate ?? transaction.transactionDate,
      isVerified: false,
      isSubscription: product?.isSubscription ?? false,
      subscriptionPeriod: product?.subscriptionPeriod?.iapSubscriptionPeriod,
      isStartTrial: isStartTrial,
      hasIntroductoryOffer: hasIntroductoryOffer,
      hasFreeTrial: hasFreeTrial,
      introductoryOfferSubscriptionPeriod: product?.introductoryPrice?.subscriptionPeriod.iapSubscriptionPeriod,
      introductoryOfferPrice: product?.introductoryPrice?.price.decimalValue,
      storeKitVersion: .version1
    )
    didResolve(event: event, for: transaction)
  }

  func resolveEventFor(transaction: SKPaymentTransaction) {
    guard let dependencies = try? Self.getDependencies() else {
      return
    }
    let productID = transaction.payment.productIdentifier
    let request = dependencies.iapSKProductRequestFactory.createRequestWith(
      productIdentifier: productID,
      transaction: transaction
    )
    request.delegate = self
    request.start()
  }
}

// MARK: - SKProductsRequestDelegate

extension IAPEventResolver: SKProductsRequestDelegate {
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    guard let iapRequest = request as? IAPSKProductsRequesting,
          let transaction = iapRequest.transaction else {
      return
    }
    let product = response.products.first
    resolveEventFor(transaction: transaction, product: product)
  }

  func request(_ request: SKRequest, didFailWithError error: Error) {
    guard let iapRequest = request as? IAPSKProductsRequesting,
          let transaction = iapRequest.transaction else {
      return
    }
    resolveEventFor(transaction: transaction, product: nil)
  }
}

// MARK: - SKProduct

extension SKProduct {
  var isSubscription: Bool {
    subscriptionPeriod?.numberOfUnits ?? 0 > 0
  }
}
