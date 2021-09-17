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

import FacebookGamingServices
import XCTest

class GamingContextPayloadObserverTests: XCTestCase {
  let gamingContextDelegate = GamingContextPayloadObserverDelegate()
  lazy var gamingContextObserver = GamingPayloadObserver(delegate: gamingContextDelegate)

  // MARK: - GamingContextObserver
  func testCreatingGamingContextObserver() {
    XCTAssertTrue(
      gamingContextObserver.delegate === gamingContextDelegate,
      "Should store the delegate it was created with"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.applicationObservers.contains(gamingContextObserver),
      "Should observe the shared application delegate upon creation"
    )
  }

  func testGamingContextObserverOpeningInvalid() throws {
    let url = try XCTUnwrap(URL(string: "file://foo"))
    XCTAssertFalse(
      gamingContextObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open an invalid url"
    )

    XCTAssertFalse(
      gamingContextDelegate.wasGamingContextDelegateCalled,
      "Should not invoke the delegate method parsedGamingContextURLContaining for an invalid url"
    )
  }

  func testGamingContextObserverOpeningURLWithMissingKeys() throws {
    let url = try SampleUnparsedAppLinkURLs.missingKeys()

    XCTAssertFalse(
      gamingContextObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with missing extras"
    )

    XCTAssertFalse(
      gamingContextDelegate.wasGamingContextDelegateCalled,
      "Should not invoke the delegate method parsedGamingContextURLContaining for an invalid url"
    )
  }

  func testOpeningURLWithMissingGameContextTokenID() throws {
    let url = try SampleUnparsedAppLinkURLs.create(contextTokenID: nil)
    XCTAssertFalse(
      gamingContextObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with a missing game request ID"
    )
    XCTAssertFalse(
      gamingContextDelegate.wasGamingContextDelegateCalled,
      "Should not invoke the delegate method parsedGamingContextURLContaining for an invalid url"
    )
  }

  func testGamingContextObserverOpeningURLWithMissingPayload() throws {
    let url = try SampleUnparsedAppLinkURLs.create(payload: nil)
    XCTAssertFalse(
      gamingContextObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should not successfully open a url with a missing payload"
    )
    XCTAssertFalse(
      gamingContextDelegate.wasGamingContextDelegateCalled,
      "Should not invoke the delegate method parsedGamingContextURLContaining for an invalid url"
    )
  }

  func testOpeningWithValidGamingContextURL() throws {
    let url = try SampleUnparsedAppLinkURLs.validGamingContextUrl()
    XCTAssertTrue(
      gamingContextObserver.application(
        UIApplication.shared,
        open: url,
        sourceApplication: nil,
        annotation: nil
      ),
      "Should successfully open a url with a valid payload"
    )

    XCTAssertTrue(
      gamingContextDelegate.wasGamingContextDelegateCalled,
      "Should invoke the delegate method parsedGamingContextURLContaining for a url with a valid payload"
    )
    XCTAssertEqual(
      gamingContextDelegate.capturedPayload?.payload,
      SampleUnparsedAppLinkURLs.Values.payload,
      "Should invoke the delegate with the expected payload"
    )
  }
}

class GamingContextPayloadObserverDelegate: GamingPayloadDelegate {
  var wasGamingContextDelegateCalled = false
  var capturedPayload: GamingPayload?

  func parsedGamingContextURLContaining(_ payload: GamingPayload) {
    wasGamingContextDelegateCalled = true
    capturedPayload = payload
  }
}
