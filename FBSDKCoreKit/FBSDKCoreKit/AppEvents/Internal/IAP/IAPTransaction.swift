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
struct IAPTransaction {
  let transaction: Transaction
  let isVerified: Bool
}

enum IAPStoreKitVersion: String {
  case version1
  case version2
}

@available(iOS 15.0, *)
extension VerificationResult<Transaction> {
  var iapTransaction: IAPTransaction {
    switch self {
    case let .unverified(transaction, _):
      return IAPTransaction(transaction: transaction, isVerified: false)
    case let .verified(transaction):
      return IAPTransaction(transaction: transaction, isVerified: true)
    }
  }
}
