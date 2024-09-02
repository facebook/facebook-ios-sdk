/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import IAPTestsHostApp

import StoreKitTest
import XCTest

@available(iOS 14.0, *)
// swiftlint:disable:this test_classes_should_be_final
// swiftlint:disable:next prefer_final_classes
class StoreKitTestCase: XCTestCase {

  static let configFileName = "FBSDKStoreKitConfigurationUnitTests"

  enum ProductIdentifiers: String, CaseIterable {
    case product1 = "com.fbsdk.p1"
  }

  // swiftlint:disable:next implicitly_unwrapped_optional
  var testSession: SKTestSession!

  override func setUp() async throws {
    try await super.setUp()
    testSession = try SKTestSession(configurationFileNamed: Self.configFileName)
    testSession.resetToDefaultState()
    testSession.clearTransactions()
    testSession.disableDialogs = true
  }

  override func tearDown() {
    testSession = nil
    super.tearDown()
  }
}
