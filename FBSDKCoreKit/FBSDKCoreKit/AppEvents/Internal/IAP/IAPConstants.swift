/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

enum IAPConstants {
  static let storeKitFreeTrialPaymentModeString = "FREE_TRIAL"
  static let gateKeeperAppEventsIfAutoLogSubs = "app_events_if_auto_log_subs"
  static let restoredPurchasesCacheKey = "com.facebook.sdk:RestoredPurchasesKey"
  static let loggedTransactionsCacheKey = "com.facebook.sdk:LoggedTransactionsKey"
  static let newCandidatesDateCacheKey = "com.facebook.sdk:NewCandidatesDateKey"
  static let transactionDateFormat = "yyyy-MM-dd HH:mm:ssZ"
  static let defaultIAPObservationTime: UInt64 = 3600000000000
}
