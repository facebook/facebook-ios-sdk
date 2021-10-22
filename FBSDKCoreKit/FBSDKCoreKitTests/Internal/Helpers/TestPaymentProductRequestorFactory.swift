/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

@available(iOS 12.2, *)
class TestPaymentProductRequestorFactory: PaymentProductRequestorCreating {
  struct Evidence {
    let requestor: TestPaymentProductRequestor
    let transaction: SKPaymentTransaction
  }

  // Dummy class to avoid polluting the shared test gatekeeper manager
  class PaymentGateKeeperManager: GateKeeperManaging {
    static func bool(forKey key: String, defaultValue: Bool) -> Bool {
      false
    }
    static func loadGateKeepers(_ completionBlock: @escaping GKManagerBlock) {
      // noop
    }
  }

  let transaction = TestPaymentTransaction(state: .deferred)
  let settings = TestSettings()
  let eventLogger = TestEventLogger()
  let store = UserDefaultsSpy()
  let loggerFactory = TestLoggerFactory()
  let graphRequestFactory = TestProductsRequestFactory()
  let receiptProvider = TestAppStoreReceiptProvider()

  var evidence = [Evidence]()

  func createRequestor(transaction: SKPaymentTransaction) -> PaymentProductRequestor {
    let requestor = TestPaymentProductRequestor(
      transaction: transaction,
      settings: settings,
      eventLogger: eventLogger,
      gateKeeperManager: PaymentGateKeeperManager.self,
      store: store,
      loggerFactory: loggerFactory,
      productsRequestFactory: graphRequestFactory,
      appStoreReceiptProvider: receiptProvider
    )
    evidence.append(Evidence(requestor: requestor, transaction: transaction))

    return requestor
  }
}
