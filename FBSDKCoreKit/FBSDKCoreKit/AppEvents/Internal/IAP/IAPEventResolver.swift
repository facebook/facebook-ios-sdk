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
struct IAPEventResolver {

  static var configuredDependencies: TypeDependencies?
  static var defaultDependencies: TypeDependencies? = .init(
    gateKeeperManager: _GateKeeperManager.self
  )

  private static let freeTrialPaymentModeString = "FREE_TRIAL"
  let gateKeeperAppEventsIfAutoLogSubs = "app_events_if_auto_log_subs"

  func resolveNewEventFor(iapTransaction: IAPTransaction) async -> IAPEvent? {
    guard let dependencies = try? Self.getDependencies() else {
      return nil
    }
    var eventName: AppEvents.Name = .purchased
    if isSubscription(transaction: iapTransaction.transaction) {
      guard dependencies.gateKeeperManager.bool(forKey: gateKeeperAppEventsIfAutoLogSubs, defaultValue: false) else {
        return nil
      }
      eventName = resolveNewSubscriptionEventName(transaction: iapTransaction.transaction)
    }
    return await resolveEventFor(iapTransaction: iapTransaction, eventName: eventName)
  }

  func resolveRestoredEventFor(iapTransaction: IAPTransaction) async -> IAPEvent? {
    guard let dependencies = try? Self.getDependencies() else {
      return nil
    }
    var eventName: AppEvents.Name = .purchaseRestored
    if isSubscription(transaction: iapTransaction.transaction) {
      guard dependencies.gateKeeperManager.bool(forKey: gateKeeperAppEventsIfAutoLogSubs, defaultValue: false) else {
        return nil
      }
      eventName = .subscribeRestore
    }
    return await resolveEventFor(iapTransaction: iapTransaction, eventName: eventName)
  }

  private func isSubscription(transaction: Transaction) -> Bool {
    let subscriptionCheck = transaction.productType == .autoRenewable ||
      transaction.productType == .nonRenewable
    return subscriptionCheck
  }

  private func isStartTrial(transaction: Transaction) -> Bool {
    var isFreeTrial = false
    if #available(iOS 17.2, *) {
      isFreeTrial = transaction.offer?.paymentMode == .freeTrial
    } else {
      isFreeTrial = transaction.offerPaymentModeStringRepresentation == Self.freeTrialPaymentModeString
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

// MARK: - DependentAsObject

@available(iOS 15.0, *)
extension IAPEventResolver: DependentAsType {
  struct TypeDependencies {
    var gateKeeperManager: _GateKeeperManaging.Type
  }
}
