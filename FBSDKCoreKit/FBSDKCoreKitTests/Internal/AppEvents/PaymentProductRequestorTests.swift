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
  lazy var tempURL = URL(
    fileURLWithPath: NSTemporaryDirectory(),
    isDirectory: true
  ).appendingPathComponent(name)
  let receiptProvider = TestAppStoreReceiptProvider()

  lazy var requestor = PaymentProductRequestor(
    transaction: transaction,
    settings: settings,
    eventLogger: eventLogger,
    gateKeeperManager: TestGateKeeperManager.self,
    store: store,
    logger: logger,
    productsRequestFactory: requestFactory,
    appStoreReceiptProvider: receiptProvider
  )

  enum Keys {
    static let receiptData = "receipt_data"
    static let implicitlyLogged = "_implicitlyLogged"
    static let existingKey = "some_parameter"
  }

  enum Values {
    static let appName = "foo"
    static let existingValue = "bar"
  }

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

  // MARK: - Device Receipt

  func testFetchingDeviceReceipt() throws {
    try seedReceiptData()
    receiptProvider.stubbedURL = tempURL

    let receiptData = requestor.fetchDeviceReceipt()

    XCTAssertTrue(
      receiptProvider.wasAppStoreReceiptURLRead,
      "Fetching the device receipt should request a url from the receipt provider"
    )
    XCTAssertEqual(
      receiptData,
      encodedAppName,
      "Fetching the device receipt should fetch the data at the receipt path"
    )
  }

  // MARK: - Logging implicit transaction events

  func testLoggingTransactionWithKnownEventNames() throws {
    try seedReceiptData()
    receiptProvider.stubbedURL = tempURL

    [AppEvents.Name.purchased, AppEvents.Name.subscribe, AppEvents.Name.startTrial].forEach { eventName in
      requestor.logImplicitTransactionEvent(
        eventName.rawValue,
        valueToSum: 100,
        parameters: [Keys.existingKey: Values.existingValue]
      )

      guard let parameters = eventLogger.capturedParameters as? [String: String] else {
        return XCTFail("Should log an event with parameters")
      }
      XCTAssertEqual(
        parameters[Keys.receiptData],
        encodedAppName.base64EncodedString(),
        "Should fetch and include the receipt data for events matching transaction names"
      )
      XCTAssertEqual(
        parameters[Keys.existingKey],
        Values.existingValue,
        "Should pass through the provided parameters"
      )
      XCTAssertEqual(
        parameters[Keys.implicitlyLogged],
        "1",
        "Should log whether the event is implicitly logged"
      )
      XCTAssertEqual(
        eventLogger.capturedValueToSum,
        100,
        "Should log the value to sum"
      )
    }
  }

  func testLoggingTransactionWithUnknownEventNames() throws {
    try seedReceiptData()
    receiptProvider.stubbedURL = tempURL

    ["foo", "bar", "baz"].forEach { eventName in
      requestor.logImplicitTransactionEvent(
        eventName,
        valueToSum: 100,
        parameters: [Keys.existingKey: Values.existingValue]
      )

      guard let parameters = eventLogger.capturedParameters as? [String: String] else {
        return XCTFail("Should log an event with parameters")
      }
      XCTAssertNil(
        parameters[Keys.receiptData],
        "Should not fetch and include the receipt data for events that do not match transaction names"
      )
      XCTAssertEqual(
        parameters[Keys.existingKey],
        Values.existingValue,
        "Should pass through the provided parameters"
      )
      XCTAssertEqual(
        parameters[Keys.implicitlyLogged],
        "1",
        "Should log whether the event is implicitly logged"
      )
      XCTAssertEqual(
        eventLogger.capturedValueToSum,
        100,
        "Should log the value to sum"
      )
    }
  }

  func testLoggingImplicitTransactionFlushes() {
    requestor.logImplicitTransactionEvent("foo", valueToSum: 100, parameters: [:])

    XCTAssertEqual(
      eventLogger.flushCallCount,
      1,
      "Should flush events once per logging attempt"
    )
    XCTAssertEqual(
      eventLogger.capturedFlushReason,
      AppEventsUtility.FlushReason.eagerlyFlushingEvent.rawValue,
      "Should capture the flush reason"
    )
  }

  func testLoggingWithExplicitFlushBehavior() {
    eventLogger.flushBehavior = .explicitOnly
    requestor.logImplicitTransactionEvent("foo", valueToSum: 100, parameters: [:])

    XCTAssertEqual(
      eventLogger.flushCallCount,
      0,
      "Should not flush events immediately when the behavior is explicit flushing only"
    )
  }

  // MARK: - Helpers

  var encodedAppName: Data {
    return Values.appName.data(using: .utf8)! // swiftlint:disable:this force_unwrapping
  }

  func seedReceiptData() throws {
    try encodedAppName.write(to: tempURL)
  }
}
