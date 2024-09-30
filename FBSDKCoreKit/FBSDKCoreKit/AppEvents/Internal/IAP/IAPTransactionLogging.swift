/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol IAPTransactionLogging {
  @available(iOS 15.0, *)
  func logNewTransaction(_ transaction: IAPTransaction) async
  @available(iOS 15.0, *)
  func logRestoredTransaction(_ transaction: IAPTransaction) async
  func logTransaction(_ transaction: SKPaymentTransaction)
}
