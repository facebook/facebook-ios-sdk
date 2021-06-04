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

import FBSDKCoreKit
import TestTools
import XCTest

class AppEventsAtePublisherTests: XCTestCase {

  let factory = TestGraphRequestFactory()
  let settings = TestSettings()
  let store = UserDefaultsSpy()
  let twelveHoursAgoInSeconds: TimeInterval = -12 * 60 * 60
  let fortyEightHoursAgoInSeconds: TimeInterval = -48 * 60 * 60
  lazy var key = "com.facebook.sdk:lastATEPing\(name)"
  lazy var publisher = AppEventsAtePublisher(
    appIdentifier: name,
    graphRequestFactory: factory,
    settings: settings,
    store: store
  )! // swiftlint:disable:this force_unwrapping

  func testCreatingWithEmptyAppIdentifier() {
    XCTAssertNil(
      AppEventsAtePublisher(
        appIdentifier: "",
        graphRequestFactory: factory,
        settings: settings,
        store: store
      ),
      "Should not create an ATE publisher with an empty app identifier"
    )
  }

  func testCreatingWithValidAppIdentifier() throws {
    XCTAssertEqual(
      publisher.appIdentifier,
      name,
      "Should be able to create a publisher with a non-empty string for the app identifier"
    )
  }

  func testPublishingAteWithoutLastPublishDate() throws {
    settings.advertisingTrackingStatus = .allowed

    publisher.publishATE()
    let request = try XCTUnwrap(factory.capturedRequests.first)
    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the request to publish the ATE"
    )
    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      "com.facebook.sdk:lastATEPing\(publisher.appIdentifier)",
      "Should use the store to access the last published date"
    )
    XCTAssertFalse(
      publisher.isProcessing,
      "After processing, isProcessing should equal to NO"
    )
  }

  func testPublishingWithNonExpiredLastPublishDate() throws {
    store.set(
      Date(timeIntervalSinceNow: twelveHoursAgoInSeconds),
      forKey: key
    )
    settings.advertisingTrackingStatus = .allowed

    publisher.publishATE()

    XCTAssertEqual(factory.capturedRequests.count, 0)
    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      key,
      "Should use the store to access the last published date"
    )
    XCTAssertFalse(
      publisher.isProcessing,
      "After processing, isProcessing should equal to NO"
    )
  }

  func testPublishingWithExpiredLastPublishDate() throws {
    store.set(
      Date(timeIntervalSinceNow: fortyEightHoursAgoInSeconds),
      forKey: key
    )
    settings.advertisingTrackingStatus = .allowed

    publisher.publishATE()

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(request.startCallCount, 1)
    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      key,
      "Should use the store to access the last published date"
    )

    XCTAssertFalse(
      publisher.isProcessing,
      "After processing, isProcessing should equal to NO"
    )
  }
}
