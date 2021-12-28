/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class HybridAppEventsScriptMessageHandlerTests: XCTestCase {

  enum Keys {
    static let valid = "key"
    static let event = "event"
    static let params = "params"
    static let pixelID = "pixelID"
    static let referralID = "_fb_pixel_referral_id"
  }

  enum Values {
    static let valid = "bar"
    static let emptyString = ""
    static let nonEmptyString = "foo"
    static let validMessageName = "fbmqHandler"
    static let validEventName = "Did the thing"
  }

  // swiftlint:disable implicitly_unwrapped_optional
  var controller: WKUserContentController!
  var eventLogger: TestEventLogger!
  var loggerAndNotifier: TestLoggingNotifier!
  var handler: HybridAppEventsScriptMessageHandler!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    controller = WKUserContentController()
    eventLogger = TestEventLogger()
    loggerAndNotifier = TestLoggingNotifier()
    handler = HybridAppEventsScriptMessageHandler(
      eventLogger: eventLogger,
      loggingNotifier: loggerAndNotifier
    )
  }

  override func tearDown() {
    controller = nil
    eventLogger = nil
    loggerAndNotifier = nil
    handler = nil

    super.tearDown()
  }

  func testCreatingWithDependencies() {
    XCTAssertTrue(
      handler.eventLogger is TestEventLogger,
      "Should use the provided event logger"
    )
    XCTAssertTrue(
      handler.loggingNotifier is TestLoggingNotifier,
      "Should use the provided logger and notifier"
    )
  }

  func testReceivingWithIncorrectNameKey() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(name: name)
    )

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log an event if the message isn't named correctly"
    )
  }

  func testReceivingWithoutEvent() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(name: Values.validMessageName)
    )

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log an event if the message has no body"
    )
  }

  func testReceivingWithEmptyEvent() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(
        name: Values.validMessageName,
        body: [Keys.event: Values.emptyString]
      )
    )

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log an event if the message's event is empty"
    )
  }

  func testReceivingWithInvalidEventTypes() {
    [
      true,
      5,
      ["foo"],
      Date(),
      "foo".data(using: .utf8) as Any,
      SampleError()
    ].forEach { input in
      handler.userContentController(
        controller,
        didReceive: TestScriptMessage(
          name: Values.validMessageName,
          body: [Keys.event: input]
        )
      )
      XCTAssertNil(
        eventLogger.capturedEventName,
        "Should not log events of invalid types"
      )
    }
  }

  func testReceivingWithoutPixelID() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(
        name: Values.validMessageName,
        body: [Keys.event: name]
      )
    )
    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log events without pixel identifiers"
    )
    XCTAssertEqual(
      loggerAndNotifier.capturedMessage,
      "Can't bridge an event without a referral Pixel ID. Check your webview Pixel configuration.",
      "Should log and notify with a useful message"
    )
  }

  func testReceivingWithEmptyParameters() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(
        name: Values.validMessageName,
        body: [
          Keys.event: Values.validEventName,
          Keys.params: Values.emptyString,
          Keys.pixelID: Values.nonEmptyString
        ]
      )
    )

    assertEventLogged(
      name: Values.validEventName,
      parameters: [Keys.referralID: Values.nonEmptyString]
    )
  }

  func testReceivingWithNonJsonParameters() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(
        name: Values.validMessageName,
        body: [
          Keys.event: Values.validEventName,
          Keys.params: name,
          Keys.pixelID: Values.nonEmptyString
        ]
      )
    )
    XCTAssertEqual(
      loggerAndNotifier.capturedMessage,
      "Could not find parameters for your Pixel request. Check your webview Pixel configuration.",
      "Should log and notify about missing parameters"
    )
    assertEventLogged(
      name: Values.validEventName,
      parameters: [Keys.referralID: Values.nonEmptyString]
    )
  }

  func testReceivingWithJsonParameters() throws {
    let data = try JSONSerialization.data(
      withJSONObject: [Keys.valid: Values.valid], options: []
    )
    let json = String(data: data, encoding: .utf8)

    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(
        name: Values.validMessageName,
        body: [
          Keys.event: Values.validEventName,
          Keys.params: json,
          Keys.pixelID: Values.nonEmptyString
        ]
      )
    )
    assertEventLogged(
      name: Values.validEventName,
      parameters: [
        Keys.valid: Values.valid,
        Keys.referralID: Values.nonEmptyString
      ]
    )
  }

  // MARK: - Helpers

  func assertEventLogged(
    name: String,
    parameters: [String: String],
    file: StaticString = #file,
    line: UInt = #line
  ) {
    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name(name),
      "Should log the expected event name",
      file: file,
      line: line
    )
    XCTAssertEqual(
      eventLogger.capturedParameters as? [String: String],
      parameters,
      "Should log the expected parameters",
      file: file,
      line: line
    )
    XCTAssertFalse(
      eventLogger.capturedIsImplicitlyLogged,
      "Should not implicitly log handled events",
      file: file,
      line: line
    )
  }

  class TestScriptMessage: WKScriptMessage {
    let stubbedName: String
    let stubbedBody: Any

    override var name: String {
      stubbedName
    }

    override var body: Any {
      stubbedBody
    }

    init(
      name: String,
      body: Any? = nil
    ) {
      stubbedName = name
      stubbedBody = body ?? ""
    }
  }
}
