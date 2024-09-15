/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import Foundation

@available(iOS 15.0, *)
struct TestIAPTransactionLoggingFactory: IAPTransactionLoggingCreating {

  func createIAPTransactionLogging() -> any IAPTransactionLogging {
    return TestIAPTransactionLogger() // swiftlint:disable:this implicit_return
  }
}
