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
  let validationResult: IAPValidationResult
}

enum IAPStoreKitVersion: String {
  case version1 = "SK1"
  case version2 = "SK2"
}

enum IAPProductType: String {
  case consumable = "Consumable"
  case nonConsumable = "NonConsumable"
  case autoRenewable = "AutoRenewable"
  case nonRenewable = "NonRenewable"
}

@available(iOS 15.0, *)
extension VerificationResult<Transaction> {
  var iapTransaction: IAPTransaction {
    switch self {
    case let .unverified(transaction, error):
      var validationResult = IAPValidationResult.unverified
      switch error {
      case .revokedCertificate:
        validationResult = .unverified
      case .invalidCertificateChain:
        validationResult = .unverified
      case .invalidDeviceVerification:
        validationResult = .invalid
      case .invalidEncoding:
        validationResult = .unverified
      case .invalidSignature:
        validationResult = .invalid
      case .missingRequiredProperties:
        validationResult = .unverified
      @unknown default:
        validationResult = .unverified
      }
      return IAPTransaction(transaction: transaction, validationResult: validationResult)
    case let .verified(transaction):
      return IAPTransaction(transaction: transaction, validationResult: .valid)
    }
  }
}
