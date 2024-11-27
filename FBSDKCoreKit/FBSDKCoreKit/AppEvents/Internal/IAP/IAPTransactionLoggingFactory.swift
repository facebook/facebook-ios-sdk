/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class IAPTransactionLoggingFactory: IAPTransactionLoggingCreating, IAPFailedTransactionLoggingCreating {

  @available(iOS 15.0, *)
  func createIAPFailedTransactionLogging() -> any IAPFailedTransactionLogging {
    return IAPTransactionLogger() // swiftlint:disable:this implicit_return
  }

  func createIAPTransactionLogging() -> any IAPTransactionLogging {
    return IAPTransactionLogger() // swiftlint:disable:this implicit_return
  }
}
