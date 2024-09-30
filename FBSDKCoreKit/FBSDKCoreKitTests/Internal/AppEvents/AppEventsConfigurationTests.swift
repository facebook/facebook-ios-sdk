/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class AppEventsConfigurationTests: XCTestCase {

  private var configuration = SampleAppEventsConfigurations.valid

  func testCreatingWithDefaultATEStatus() {
    XCTAssertEqual(configuration.defaultATEStatus, .unspecified, "Default ATE Status should be unspecified")
  }

  func testCreatingWithKnownDefaultATEStatus() {
    configuration = SampleAppEventsConfigurations.create(defaultATEStatus: AdvertisingTrackingStatus.allowed)
    XCTAssertEqual(configuration.defaultATEStatus, .allowed, "Default ATE Status should be settable")
  }

  func testCreatingWithDefaultAdvertisingIDCollectionEnabled() {
    XCTAssertTrue(
      configuration.advertiserIDCollectionEnabled,
      "Advertising identifier collection enabled should default to true"
    )
  }

  func testCreatingWithKnownAdvertisingIDCollectionEnabled() {
    configuration = SampleAppEventsConfigurations.create(advertiserIDCollectionEnabled: false)
    XCTAssertFalse(
      configuration.advertiserIDCollectionEnabled,
      "Advertising identifier collection enabled should be settable"
    )
  }

  func testCreatingWithDefaultEventCollectionEnabled() {
    XCTAssertFalse(configuration.eventCollectionEnabled, "Event collection enabled should default to false")
  }

  func testCreatingWithKnownEventCollectionEnabled() {
    configuration = SampleAppEventsConfigurations.create(eventCollectionEnabled: true)
    XCTAssertTrue(configuration.eventCollectionEnabled, "Event collection enabled should be settable")
  }

  func testCreatingWithDefaultIAPObservationTime() {
    XCTAssertEqual(configuration.iapObservationTime, 3600000000000)
  }

  func testCreatingWithKnownIAPObservationTime() {
    configuration = SampleAppEventsConfigurations.create(iapObservationTime: 1800000000000)
    XCTAssertEqual(configuration.iapObservationTime, 1800000000000)
  }

  func testCodingSecurity() {
    XCTAssertTrue(_AppEventsConfiguration.supportsSecureCoding, "Should support secure coding")
  }

  func testCreatingWithMissingDictionary() {
    configuration = _AppEventsConfiguration(json: nil)
    XCTAssertEqual(
      configuration,
      _AppEventsConfiguration.default(),
      "Should use the default configuration when creating with a missing dictionary"
    )
  }

  func testCreatingWithEmptyDictionary() {
    configuration = _AppEventsConfiguration(json: [:])
    XCTAssertEqual(
      configuration,
      _AppEventsConfiguration.default(),
      "Should use the default configuration when creating with an empty dictionary"
    )
  }

  func testCreatingWithMissingTopLevelKey() {
    configuration = _AppEventsConfiguration(
      json: RawAppEventsConfigurationResponseFixtures.validMissingTopLevelKey
    )
    XCTAssertEqual(
      configuration,
      _AppEventsConfiguration.default(),
      "Should use the default configuration when creating with a missing top level key"
    )
  }

  func testCreatingWithInvalidValues() {
    configuration = _AppEventsConfiguration(
      json: RawAppEventsConfigurationResponseFixtures.invalidValues
    )
    XCTAssertEqual(
      configuration.defaultATEStatus,
      .unspecified,
      "Should use the correct default for ate status"
    )
    XCTAssertTrue(
      configuration.advertiserIDCollectionEnabled,
      "Should use the correct default for ad ID collection"
    )
    XCTAssertFalse(
      configuration.eventCollectionEnabled,
      "Should use the correct default for event collection"
    )
  }

  func testCreatingWithValidValues() {
    configuration = _AppEventsConfiguration(json: RawAppEventsConfigurationResponseFixtures.valid)
    XCTAssertEqual(
      configuration.defaultATEStatus,
      .disallowed,
      "Should use the provided value for the default ate status"
    )
    XCTAssertFalse(
      configuration.advertiserIDCollectionEnabled,
      "Should use the provided value for ad ID collection"
    )
    XCTAssertTrue(
      configuration.eventCollectionEnabled,
      "Should use the provided value for event collection"
    )
  }

  // MARK: Coding

  func testEncodingAndDecoding() throws {
    configuration = _AppEventsConfiguration.default()
    let decodedObject = try CodabilityTesting.encodeAndDecode(configuration)

    // Test Objects
    XCTAssertNotIdentical(decodedObject, configuration, .isCodable)
    XCTAssertEqual(decodedObject, configuration, .isCodable)

    // Test Properties
    XCTAssertEqual(
      configuration.defaultATEStatus,
      decodedObject.defaultATEStatus,
      .isCodable
    )
    XCTAssertEqual(
      configuration.advertiserIDCollectionEnabled,
      decodedObject.advertiserIDCollectionEnabled,
      .isCodable
    )
    XCTAssertEqual(
      configuration.eventCollectionEnabled,
      decodedObject.eventCollectionEnabled,
      .isCodable
    )
    XCTAssertEqual(
      configuration.iapObservationTime,
      decodedObject.iapObservationTime,
      .isCodable
    )
  }
}

// swiftformat:disable extensionaccesscontrol

extension _AppEventsConfiguration {
  // swiftlint:disable:next override_in_extension
  open override func isEqual(_ object: Any?) -> Bool {
    if let other = object as? _AppEventsConfiguration {
      return advertiserIDCollectionEnabled == other.advertiserIDCollectionEnabled &&
        eventCollectionEnabled == other.eventCollectionEnabled &&
        defaultATEStatus == other.defaultATEStatus &&
        iapObservationTime == other.iapObservationTime
    } else {
      return super.isEqual(object)
    }
  }
}

fileprivate extension String {
  static let isCodable = "_AppEventsConfiguration should be encodable and decodable"
}
