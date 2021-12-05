/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices
import XCTest

class GamingRequestPayloadObserverTests: XCTestCase {

  let gameRequestDelegate = GameRequestPayloadObserverDelegate()
  lazy var gameRequestObserver = GamingPayloadObserver(delegate: gameRequestDelegate)
  var capturedPayload: GamingPayload?

  func testCreatingObserver() {
    XCTAssertTrue(
      gameRequestObserver.delegate === gameRequestDelegate,
      "Should store the delegate it was created with"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.applicationObservers.contains(gameRequestObserver),
      "Should observe the shared application delegate upon creation"
    )
  }

  func testOpeningInvalidURL() throws {
    let url = try XCTUnwrap(URL(string: "file://foo"))
    XCTAssertFalse(
      gameRequestObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open an invalid url"
    )

    XCTAssertFalse(
      gameRequestDelegate.wasGameRequestDelegateCalled,
      "Should not invoke the delegate method parsedGameRequestURLContaining for an invalid url"
    )
  }

  func testOpeningURLWithMissingKeys() throws {
    let url = try SampleUnparsedAppLinkURLs.missingKeys()

    XCTAssertFalse(
      gameRequestObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with missing extras"
    )

    XCTAssertFalse(
      gameRequestDelegate.wasGameRequestDelegateCalled,
      "Should not invoke the delegate method parsedGameRequestURLContaining for an invalid url"
    )
  }

  func testOpeningURLWithMissingGameRequestID() throws {
    let url = try SampleUnparsedAppLinkURLs.create(gameRequestID: nil)
    XCTAssertFalse(
      gameRequestObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with a missing game request ID"
    )
    XCTAssertFalse(
      gameRequestDelegate.wasGameRequestDelegateCalled,
      "Should not invoke the delegate method parsedGameRequestURLContaining for an invalid url"
    )
  }

  func testOpeningURLWithMissingPayload() throws {
    let url = try SampleUnparsedAppLinkURLs.create(payload: nil)
    XCTAssertFalse(
      gameRequestObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with a missing payload"
    )
    XCTAssertFalse(
      gameRequestDelegate.wasGameRequestDelegateCalled,
      "Should not invoke the delegate method parsedGameRequestURLContaining for an invalid url"
    )
  }

  func testOpeningWithValidGameRequestURL() throws {
    let url = try SampleUnparsedAppLinkURLs.validGameRequestUrl()
    XCTAssertTrue(
      gameRequestObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should successfully open a url with a valid payload"
    )
    XCTAssertTrue(
      gameRequestDelegate.wasGameRequestDelegateCalled,
      "Should invoke the delegate method parsedGameRequestURLContaining for a url with a valid payload"
    )
    XCTAssertEqual(
      gameRequestDelegate.capturedPayload?.payload,
      SampleUnparsedAppLinkURLs.Values.payload,
      "Should invoke the delegate with the expected payload"
    )
    XCTAssertEqual(
      gameRequestDelegate.capturedGameRequestID,
      SampleUnparsedAppLinkURLs.Values.gameRequestID,
      "Should invoke the delegate with the expected game request ID"
    )
  }
}

class GameRequestPayloadObserverDelegate: NSObject, GamingPayloadDelegate {
  var wasGameRequestDelegateCalled = false
  var capturedGameRequestID: String?
  var capturedPayload: GamingPayload?

  func parsedGameRequestURLContaining(_ payload: GamingPayload, gameRequestID: String) {
    wasGameRequestDelegateCalled = true
    capturedGameRequestID = gameRequestID
    capturedPayload = payload
  }
}
