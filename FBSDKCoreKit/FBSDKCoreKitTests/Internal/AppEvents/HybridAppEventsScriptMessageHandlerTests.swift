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
