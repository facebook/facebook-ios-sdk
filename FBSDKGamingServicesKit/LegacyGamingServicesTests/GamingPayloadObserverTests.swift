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

class GamingPayloadObserverTests: XCTestCase, GamingPayloadDelegate {

  lazy var observer = GamingPayloadObserver(delegate: self)
  var capturedPayload: GamingPayload?
  var wasUpdatedURLContainingCalled = false

  func testCreating() {
    XCTAssertTrue(
      observer.delegate === self,
      "Should store the delegate it was created with"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.applicationObservers.contains(observer),
      "Should observe the shared application delegate upon creation"
    )
  }

  func testOpeningInvalidURL() throws {
    // non fbsdkurl
    let url = try XCTUnwrap(URL(string: "file://foo"))
    XCTAssertFalse(
      observer.application(
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

  func testOpeningURLWithMissingKeys() throws {
    let url = try SampleUnparsedAppLinkURLs.missingKeys()

    XCTAssertFalse(
      observer.application(
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

  func testOpeningURLWithMissingGameRequestID() throws {
    let url = try SampleUnparsedAppLinkURLs.create(gameRequestID: nil)
    XCTAssertTrue(
      observer.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should successfully open a url with a missing game request ID"
    )
    XCTAssertTrue(
      wasUpdatedURLContainingCalled,
      "Should invoke the delegate for a url with a missing game request ID"
    )
  }

  func testOpeningURLWithMissingPayload() throws {
    let url = try SampleUnparsedAppLinkURLs.create(payload: nil)
    XCTAssertTrue(
      observer.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should successfully open a url with a missing payload"
    )
    XCTAssertTrue(
      wasUpdatedURLContainingCalled,
      "Should invoke the delegate for a url with a missing payload"
    )
  }

  func testOpeningWithValidURL() throws {
    let url = try SampleUnparsedAppLinkURLs.valid()
    XCTAssertTrue(
      observer.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should successfully open a url with a valid payload"
    )

    XCTAssertTrue(
      wasUpdatedURLContainingCalled,
      "Should invoke the delegate for a url with a valid payload"
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

  // MARK: - GamingPayload Delegate

  func updatedURLContaining(_ payload: GamingPayload) {
    wasUpdatedURLContainingCalled = true
    capturedPayload = payload
  }
}
