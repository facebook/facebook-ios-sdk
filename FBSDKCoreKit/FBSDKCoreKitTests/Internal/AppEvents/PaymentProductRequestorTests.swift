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

import XCTest

class PaymentProductRequestorTests: XCTestCase {

  var transaction = TestPaymentTransaction(state: .deferred)
  var requestFactory = TestProductsRequestFactory()
  let settings = TestSettings()
  let eventLogger = TestEventLogger()
  let store = UserDefaultsSpy()
  let logger = TestLogger()

  lazy var requestor = PaymentProductRequestor(
    transaction: transaction,
    settings: settings,
    eventLogger: eventLogger,
    gateKeeperManager: TestGateKeeperManager.self,
    store: store,
    logger: logger,
    productsRequestFactory: requestFactory
  )

  func testResolvingProducts() {
    requestor.resolveProducts()

    XCTAssertEqual(
      requestFactory.capturedProductIdentifiers,
      Set([transaction.payment.productIdentifier]),
      "Should use the product identifier from the transaction's payment to create the products request"
    )
    XCTAssertEqual(
      requestor.productsRequest.delegate as? PaymentProductRequestor,
      requestor,
      "Should set the requestor as the products request delegate when resolving products"
    )
    XCTAssertEqual(
      requestFactory.request.startCallCount,
      1,
      "Should start the products request when resolving products"
    )
    XCTAssertTrue(
      PaymentProductRequestor.pendingRequestors.contains(requestor),
      "Should maintain a list of strong references to requestors performing requests"
    )
  }
}
