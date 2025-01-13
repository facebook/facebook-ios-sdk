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
  static let oldestCachedTransactionkey = "com.facebook.sdk:OldestCachedTransactionKey"
  static let transactionDateFormat = "yyyy-MM-dd HH:mm:ssZ"
  static let defaultIAPObservationTime: UInt64 = 3600000000000
  static let defaultIAPDedupeWindow: TimeInterval = 60
  static let IAPSDKLibraryVersions = "SK1-SK2"
  static let dedupableEvents: Set<AppEvents.Name> = [.purchased, .subscribe, .startTrial]
  static let verifiableEvents: Set<AppEvents.Name> = [
    .purchased,
    .subscribe,
    .startTrial,
    .purchaseRestored,
    .subscribeRestore,
  ]
  static let manuallyLoggedDedupableEventsKey = "com.facebook.sdk:ManualDedupableEventsKey"
  static let implicitlyLoggedDedupableEventsKey = "com.facebook.sdk:ImplicitDedupableEventsKey"
  static let sk2ReleaseDate = "2025-01-14"
  static let consumablesInPurchaseHistoryKey = "SKIncludeConsumableInAppPurchaseHistory"
}
