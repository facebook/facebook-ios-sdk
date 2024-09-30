/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

struct IAPEvent: Equatable {
  let eventName: AppEvents.Name
  let productID: String
  let productTitle: String?
  let productDescription: String?
  let amount: Decimal
  let quantity: Int
  let currency: String?
  let transactionID: String?
  let originalTransactionID: String?
  let transactionDate: Date?
  let originalTransactionDate: Date?
  let isVerified: Bool
  let isSubscription: Bool
  let subscriptionPeriod: IAPSubscriptionPeriod?
  let isStartTrial: Bool
  let hasIntroductoryOffer: Bool
  let hasFreeTrial: Bool
  let introductoryOfferSubscriptionPeriod: IAPSubscriptionPeriod?
  let introductoryOfferPrice: Decimal?
  let storeKitVersion: IAPStoreKitVersion
}
