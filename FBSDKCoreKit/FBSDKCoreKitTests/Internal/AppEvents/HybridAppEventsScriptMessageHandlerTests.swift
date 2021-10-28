/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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

  let controller = WKUserContentController()
  let logger = TestEventLogger()
  lazy var handler = HybridAppEventsScriptMessageHandler(eventLogger: logger)

  func testCreatingWithDefaults() {
    handler = HybridAppEventsScriptMessageHandler()

    XCTAssertEqual(
      ObjectIdentifier(handler.eventLogger),
      ObjectIdentifier(AppEvents.shared),
      "Should use the correct concrete event logger by default"
    )
  }

  func testReceivingWithIncorrectNameKey() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(name: name)
    )

    XCTAssertNil(
      logger.capturedEventName,
      "Should not log an event if the message isn't named correctly"
    )
  }

  func testReceivingWithoutEvent() {
    handler.userContentController(
      controller,
      didReceive: TestScriptMessage(name: Values.validMessageName)
    )

    XCTAssertNil(
      logger.capturedEventName,
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
      logger.capturedEventName,
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
        logger.capturedEventName,
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
      logger.capturedEventName,
      "Should not log events without pixel identifiers"
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
      logger.capturedEventName,
      AppEvents.Name(name),
      "Should log the expected event name",
      file: file,
      line: line
    )
    XCTAssertEqual(
      logger.capturedParameters as? [String: String],
      parameters,
      "Should log the expected parameters",
      file: file,
      line: line
    )
    XCTAssertFalse(
      logger.capturedIsImplicitlyLogged,
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
