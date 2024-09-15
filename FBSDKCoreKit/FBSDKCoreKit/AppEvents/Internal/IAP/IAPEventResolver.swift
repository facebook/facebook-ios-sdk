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

  private static let freeTrialPaymentModeString = "FREE_TRIAL"

  func resolveNewEventFor(iapTransaction: IAPTransaction) async -> IAPEvent? {
    var eventName: AppEvents.Name = .purchased
    if isSubscription(transaction: iapTransaction.transaction) {
      eventName = resolveNewSubscriptionEventName(transaction: iapTransaction.transaction)
    }
    return await resolveEventFor(iapTransaction: iapTransaction, eventName: eventName)
  }

  func resolveRestoredEventFor(iapTransaction: IAPTransaction) async -> IAPEvent? {
    var eventName: AppEvents.Name = .purchaseRestored
    if isSubscription(transaction: iapTransaction.transaction) {
      eventName = .subscribeRestore
    }
    return await resolveEventFor(iapTransaction: iapTransaction, eventName: eventName)
  }

  private func isSubscription(transaction: Transaction) -> Bool {
    let subscriptionCheck = transaction.productType == .autoRenewable ||
      transaction.productType == .nonRenewable
    return subscriptionCheck
  }

  private func resolveNewSubscriptionEventName(transaction: Transaction) -> AppEvents.Name {
    var isFreeTrial = false
    if #available(iOS 17.2, *) {
      isFreeTrial = transaction.offer?.paymentMode == .freeTrial
    } else {
      isFreeTrial = transaction.offerPaymentModeStringRepresentation == Self.freeTrialPaymentModeString
    }
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
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: transaction.purchaseDate,
      originalTransactionDate: transaction.originalPurchaseDate,
      isVerified: iapTransaction.isVerified,
      subscriptionPeriod: product.subscription?.subscriptionPeriod.iapSubscriptionPeriod,
      hasIntroductoryOffer: hasIntroductoryOffer,
      hasFreeTrial: hasFreeTrial,
      introductoryOfferSubscriptionPeriod: introOffer?.period.iapSubscriptionPeriod,
      introductoryOfferPrice: introOffer?.price
    )
  }
}
