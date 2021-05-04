// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
  let requestFactory = TestProductsRequestFactory()
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
      productsRequestFactory: requestFactory,
      appStoreReceiptProvider: receiptProvider
    )
    evidence.append(Evidence(requestor: requestor, transaction: transaction))

    return requestor
  }
}
