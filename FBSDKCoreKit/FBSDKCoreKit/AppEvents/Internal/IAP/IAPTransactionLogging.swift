/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@available(iOS 15.0, *)
protocol IAPTransactionLogging {
  func logNewTransaction(_ transaction: IAPTransaction) async
  func logRestoredTransaction(_ transaction: IAPTransaction) async
}
