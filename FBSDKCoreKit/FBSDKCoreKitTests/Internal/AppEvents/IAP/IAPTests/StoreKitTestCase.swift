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

// swiftlint:disable:this test_classes_should_be_final
// swiftlint:disable:next prefer_final_classes
class StoreKitTestCase: XCTestCase {

  static let configFileName = "FBSDKStoreKitConfigurationUnitTests"

  enum ProductIdentifiers: String, CaseIterable {
    case consumableProduct1 = "com.fbsdk.consumable.p1"
    case nonConsumableProduct1 = "com.fbsdk.nonconsumable.p1"
    case nonConsumableProduct2 = "com.fbsdk.nonconsumable.p2"
    case autoRenewingSubscription1 = "com.fbsdk.autorenewing.s1"
    case autoRenewingSubscription2 = "com.fbsdk.autorenewing.s2"
    case nonRenewingSubscription1 = "com.fbsdk.nonrenewing.s1"
  }

  enum StoreKitTestCaseError: Error {
    case purchaseFailed
  }

  static var allIdentifiers = ProductIdentifiers.allCases.map { id in
    id.rawValue
  }

  private var anyTestSession: Any?

  @available(iOS 15.0, *)
  func getIAPTransactionForPurchaseResult(result: Product.PurchaseResult) throws -> IAPTransaction {
    switch result {
    case let .success(verificationResult):
      return verificationResult.iapTransaction
    default:
      throw StoreKitTestCaseError.purchaseFailed
    }
  }

  private var transactionUpdatesTask: Task<Void, Never>?

  override func setUp() async throws {
    try await super.setUp()
    IAPTransactionCache.shared.reset()
    startObservingTransactionUpdates()
    if #available(iOS 14.0, *) {
      try setupTestSession()
    }
  }

  override func tearDown() {
    transactionUpdatesTask?.cancel()
    transactionUpdatesTask = nil
    if #available(iOS 14.0, *) {
      tearDownTestSession()
    }
    super.tearDown()
  }

  /// StoreKit emits "Making a purchase without listening for transaction updates
  /// risks missing successful purchases. Create a Task to iterate
  /// Transaction.updates at launch." on every `Product.purchase()` in this target,
  /// because nothing here iterated that sequence. Drain it for the lifetime of
  /// each test so updates have a consumer.
  ///
  /// Deliberately does not call `finish()` on what it receives: several tests
  /// depend on specific transactions staying unfinished, and finishing them here
  /// would silently change what they are asserting.
  private func startObservingTransactionUpdates() {
    guard #available(iOS 15.0, *) else { return }

    transactionUpdatesTask = Task.detached {
      // Draining is the whole point; cancelling the task in tearDown ends the
      // iteration, so there is nothing to do per element.
      for await _ in Transaction.updates {}
    }
  }
}

@available(iOS 14.0, *)
extension StoreKitTestCase {
  var testSession: SKTestSession {
    anyTestSession as! SKTestSession // swiftlint:disable:this force_cast
  }

  func setupTestSession() throws {
    anyTestSession = try SKTestSession(configurationFileNamed: Self.configFileName)
    testSession.resetToDefaultState()
    testSession.clearTransactions()
    testSession.disableDialogs = true
  }

  func tearDownTestSession() {
    anyTestSession = nil
  }
}
