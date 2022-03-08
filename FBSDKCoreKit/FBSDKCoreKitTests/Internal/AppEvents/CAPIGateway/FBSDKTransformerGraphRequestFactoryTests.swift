/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import TestTools
import XCTest

class FBSDKTransformerGraphRequestFactoryTests: XCTestCase {

  enum Keys {
    static let eventName = "event_name"
  }

  enum Values {
    static let datasetID = "id123"
    static let accessKey = "key123"
    static let cloudbridgeURL = "www.123.com"
    static let testEvent = "test"
  }

  override func setUp() {
    super.setUp()

    FBSDKTransformerGraphRequestFactory.shared.credentials = nil
    FBSDKTransformerGraphRequestFactory.shared.transformedEvents = []
  }

  func testConfigure() {
    FBSDKTransformerGraphRequestFactory.shared.configure(
      datasetID: Values.datasetID,
      url: Values.cloudbridgeURL,
      accessKey: Values.accessKey
    )

    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.credentials?.datasetID,
      Values.datasetID,
      "Credential's dataset ID is not expected"
    )
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.credentials?.accessKey,
      Values.accessKey,
      "Credential's access key is not expected"
    )
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.credentials?.capiGatewayURL,
      Values.cloudbridgeURL,
      "Credential's cloudbridge url is not expected"
    )
  }

  func testErrorHandlingWithServerError() throws {
    let url = try XCTUnwrap(URL(string: "graph.facebook.com"))
    var response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: "HTTP/1.1", headerFields: nil)

    FBSDKTransformerGraphRequestFactory.shared.handleError(
      response: response,
      events: [[Keys.eventName: Values.testEvent]]
    )
    XCTAssertTrue(
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.isEmpty,
      "Should not re-append the events to the cache queue if the request fails for server error with 400"
    )

    response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil)

    FBSDKTransformerGraphRequestFactory.shared.handleError(
      response: response,
      events: [[Keys.eventName: Values.testEvent]]
    )
    XCTAssertTrue(
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.isEmpty,
      "Should not re-append the events to the cache queue if the request fails for server error with 500"
    )
  }

  func testErrorHandlingWithoutServerError() throws {
    let url = try XCTUnwrap(URL(string: "graph.facebook.com"))
    let response = HTTPURLResponse(url: url, statusCode: 503, httpVersion: "HTTP/1.1", headerFields: nil)

    FBSDKTransformerGraphRequestFactory.shared.transformedEvents = [[Keys.eventName: "purchase"]]
    FBSDKTransformerGraphRequestFactory.shared.handleError(
      response: response,
      events: [[Keys.eventName: Values.testEvent]]
    )
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.count,
      2,
      "Should re-append the events to the cache queue if the request fails for connecty issue"
    )
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.first as? [String: String],
      [Keys.eventName: Values.testEvent],
      "The appended event is not expected"
    )
  }

  func testAppendEventsOverLimits() {
    let event = [Keys.eventName: Values.testEvent]
    var events: [[String: Any]] = []
    for _ in 0..<100 {
      events.append(event)
    }

    for _ in 0..<990 {
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.append(event)
    }

    FBSDKTransformerGraphRequestFactory.shared.appendEvents(events: events)
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.count,
      1000,
      "Cached event queue should have events no more than 1000"
    )
  }

  func testAppendEventsWithinLimits() {
    let event = [Keys.eventName: Values.testEvent]
    var events: [[String: Any]] = []

    for _ in 0..<100 {
      events.append(event)
    }

    for _ in 0..<10 {
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.append(event)
    }

    FBSDKTransformerGraphRequestFactory.shared.appendEvents(events: events)
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.transformedEvents.count,
      110,
      "Cached event queue has unexpected number of events"
    )
  }
}
