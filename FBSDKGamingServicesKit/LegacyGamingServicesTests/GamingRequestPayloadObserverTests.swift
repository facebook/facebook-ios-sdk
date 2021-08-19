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

import LegacyGamingServices
import XCTest

class GamingRequestPayloadObserverTests: XCTestCase, GamingPayloadDelegate {
  let gameRequestDelegate = GameRequestPayloadObserverDelegate()
  lazy var gameRequestObserver = GamingPayloadObserver(delegate: gameRequestDelegate)
  lazy var gameRequestObserverDeprecated = GamingPayloadObserver(delegate: self)
  var capturedPayload: GamingPayload?
  var wasUpdatedURLContainingCalled = false

  // MARK: - GameRequestObserver Implementing Deprecrated Delegate Method

  func testCreatingWithDeprecratedDelegateMethod() {
    XCTAssertTrue(
      gameRequestObserverDeprecated.delegate === self,
      "Should store the delegate it was created with"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.applicationObservers.contains(gameRequestObserverDeprecated),
      "Should observe the shared application delegate upon creation"
    )
  }

  func testOpeningInvalidURLWithDeprecratedDelegateMethod() throws {
    // non fbsdkurl
    let url = try XCTUnwrap(URL(string: "file://foo"))
    XCTAssertFalse(
      gameRequestObserverDeprecated.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open an invalid url"
    )

    XCTAssertFalse(
      wasUpdatedURLContainingCalled,
      "Should not invoke the delegate for an invalid url"
    )
  }

  func testOpeningURLWithMissingKeysWithDeprecratedDelegateMethod() throws {
    let url = try SampleUnparsedAppLinkURLs.missingKeys()

    XCTAssertFalse(
      gameRequestObserverDeprecated.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with missing extras"
    )

    XCTAssertFalse(
      wasUpdatedURLContainingCalled,
      "Should not invoke the delegate for a url with missing extras"
    )
  }

  func testOpeningURLWithMissingGameRequestIDWithDeprecratedDelegateMethod() throws {
    let url = try SampleUnparsedAppLinkURLs.create(gameRequestID: nil)
    XCTAssertFalse(
      gameRequestObserverDeprecated.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with a missing game request ID"
    )
    XCTAssertFalse(
      wasUpdatedURLContainingCalled,
      "Should not invoke the delegate method updatedURLContaining for a url with a missing game request ID"
    )
  }

  func testOpeningURLWithMissingPayloadWithDeprecratedDelegateMethod() throws {
    let url = try SampleUnparsedAppLinkURLs.create(payload: nil)
    XCTAssertFalse(
      gameRequestObserverDeprecated.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with a missing payload"
    )
    XCTAssertFalse(
      wasUpdatedURLContainingCalled,
      "Should not invoke the delegate for a url with a missing payload"
    )
  }

  func testOpeningWithValidGameRequestURLWithDeprecratedDelegateMethod() throws {
    let url = try SampleUnparsedAppLinkURLs.validGameRequestUrl()
    XCTAssertTrue(
      gameRequestObserverDeprecated.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should successfully open a game request url with a valid payload"
    )

    XCTAssertTrue(
      wasUpdatedURLContainingCalled,
      "Should invoke the delegate method updatedURLContainingCalled for a game request url with a valid payload"
    )
    XCTAssertEqual(
      capturedPayload?.payload,
      SampleUnparsedAppLinkURLs.Values.payload,
      "Should invoke the delegate with the expected payload"
    )
    XCTAssertEqual(
      capturedPayload?.gameRequestID,
      SampleUnparsedAppLinkURLs.Values.gameRequestID,
      "Should invoke the delegate with the expected game request ID"
    )
  }

  // MARK: - GameRequestObserver with Nondeprecrated Delegate Method

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
    XCTAssertFalse(
      gameRequestDelegate.wasDeprecratedMethodCalled,
      "Should not invoke the delegate method updatedURLContaining for an invalid url"
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
    XCTAssertFalse(
      gameRequestDelegate.wasDeprecratedMethodCalled,
      "Should not invoke the delegate method updatedURLContaining for an invalid url"
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
    XCTAssertFalse(
      gameRequestDelegate.wasDeprecratedMethodCalled,
      "Should not invoke the delegate method updatedURLContaining for an invalid url"
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
    XCTAssertFalse(
      gameRequestDelegate.wasDeprecratedMethodCalled,
      "Should not invoke the delegate method updatedURLContaining for an invalid url"
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

    XCTAssertFalse(
      gameRequestDelegate.wasDeprecratedMethodCalled,
      "Should not invoke the delegate method updatedURLContainingCalled for a url with a valid payload"
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

  // MARK: - GamingPayload Deprecrated Delegate Method

  func updatedURLContaining(_ payload: GamingPayload) {
    wasUpdatedURLContainingCalled = true
    capturedPayload = payload
  }
}

class GameRequestPayloadObserverDelegate: GamingPayloadDelegate {
  var wasGameRequestDelegateCalled = false
  var wasDeprecratedMethodCalled = false
  var capturedGameRequestID: String?
  var capturedPayload: GamingPayload?

  func updatedURLContaining(_ payload: GamingPayload) {
    wasDeprecratedMethodCalled = true
  }

  func parsedGameRequestURLContaining(_ payload: GamingPayload, gameRequestID: String) {
    wasGameRequestDelegateCalled = true
    capturedGameRequestID = gameRequestID
    capturedPayload = payload
  }

}
