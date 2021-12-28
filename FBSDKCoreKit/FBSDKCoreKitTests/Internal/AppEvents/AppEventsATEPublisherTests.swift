/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class AppEventsATEPublisherTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var factory: TestGraphRequestFactory!
  var settings: TestSettings!
  var store: UserDefaultsSpy!
  var deviceInformationProvider: TestDeviceInformationProvider!
  var publisher: AppEventsATEPublisher!
  // swiftlint:enable implicitly_unwrapped_optional

  let twelveHoursAgoInSeconds: TimeInterval = -12 * 60 * 60
  let fortyEightHoursAgoInSeconds: TimeInterval = -48 * 60 * 60
  lazy var key = "com.facebook.sdk:lastATEPing\(name)"

  override func setUp() {
    super.setUp()

    factory = TestGraphRequestFactory()
    settings = TestSettings()
    store = UserDefaultsSpy()
    deviceInformationProvider = TestDeviceInformationProvider()
    publisher = AppEventsATEPublisher(
      appIdentifier: name,
      graphRequestFactory: factory,
      settings: settings,
      store: store,
      deviceInformationProvider: deviceInformationProvider
    )! // swiftlint:disable:this force_unwrapping
  }

  override func tearDown() {
    factory = nil
    settings = nil
    store = nil
    deviceInformationProvider = nil
    publisher = nil

    super.tearDown()
  }

  func testCreatingWithEmptyAppIdentifier() {
    XCTAssertNil(
      AppEventsATEPublisher(
        appIdentifier: "",
        graphRequestFactory: factory,
        settings: settings,
        store: store,
        deviceInformationProvider: deviceInformationProvider
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

  func testPublishingATEUsesDeviceInformation() throws {
    settings.advertisingTrackingStatus = .allowed

    publisher.publishATE()

    XCTAssertTrue(
      deviceInformationProvider.encodedDeviceInfoWasCalled,
      "Should use device information when publishing ATE"
    )
  }

  func testPublishingATEWithoutLastPublishDate() throws {
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
