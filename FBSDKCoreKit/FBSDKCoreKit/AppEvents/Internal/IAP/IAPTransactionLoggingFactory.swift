/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct IAPTransactionLoggingFactory: IAPTransactionLoggingCreating {

  func createIAPTransactionLogging() -> any IAPTransactionLogging {
    return IAPTransactionLogger() // swiftlint:disable:this implicit_return
  }
}
