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

  private var config = SampleAppEventsConfigurations.valid

  func testCreatingWithDefaultATEStatus() {
    XCTAssertEqual(config.defaultATEStatus, .unspecified, "Default ATE Status should be unspecified")
  }

  func testCreatingWithKnownDefaultATEStatus() {
    config = SampleAppEventsConfigurations.create(defaultATEStatus: AdvertisingTrackingStatus.allowed)
    XCTAssertEqual(config.defaultATEStatus, .allowed, "Default ATE Status should be settable")
  }

  func testCreatingWithDefaultAdvertisingIDCollectionEnabled() {
    XCTAssertTrue(
      config.advertiserIDCollectionEnabled,
      "Advertising identifier collection enabled should default to true"
    )
  }

  func testCreatingWithKnownAdvertisingIDCollectionEnabled() {
    config = SampleAppEventsConfigurations.create(advertiserIDCollectionEnabled: false)
    XCTAssertFalse(config.advertiserIDCollectionEnabled, "Advertising identifier collection enabled should be settable")
  }

  func testCreatingWithDefaultEventCollectionEnabled() {
    XCTAssertFalse(config.eventCollectionEnabled, "Event collection enabled should default to false")
  }

  func testCreatingWithKnownEventCollectionEnabled() {
    config = SampleAppEventsConfigurations.create(eventCollectionEnabled: true)
    XCTAssertTrue(config.eventCollectionEnabled, "Event collection enabled should be settable")
  }

  func testCodingSecurity() {
    XCTAssertTrue(AppEventsConfiguration.supportsSecureCoding, "Should support secure coding")
  }

  func testCreatingWithMissingDictionary() {
    config = AppEventsConfiguration(json: nil)
    XCTAssertEqual(
      config,
      AppEventsConfiguration.default(),
      "Should use the default config when creating with a missing dictionary"
    )
  }

  func testCreatingWithEmptyDictionary() {
    config = AppEventsConfiguration(json: [:])
    XCTAssertEqual(
      config,
      AppEventsConfiguration.default(),
      "Should use the default config when creating with an empty dictionary"
    )
  }

  func testCreatingWithMissingTopLevelKey() {
    config = AppEventsConfiguration(
      json: RawAppEventsConfigurationResponseFixtures.validMissingTopLevelKey
    )
    XCTAssertEqual(
      config,
      AppEventsConfiguration.default(),
      "Should use the default config when creating with a missing top level key"
    )
  }

  func testCreatingWithInvalidValues() {
    config = AppEventsConfiguration(
      json: RawAppEventsConfigurationResponseFixtures.invalidValues
    )
    XCTAssertEqual(
      config.defaultATEStatus,
      .unspecified,
      "Should use the correct default for ate status"
    )
    XCTAssertTrue(
      config.advertiserIDCollectionEnabled,
      "Should use the correct default for ad ID collection"
    )
    XCTAssertFalse(
      config.eventCollectionEnabled,
      "Should use the correct default for event collection"
    )
  }

  func testCreatingWithValidValues() {
    config = AppEventsConfiguration(json: RawAppEventsConfigurationResponseFixtures.valid)
    XCTAssertEqual(
      config.defaultATEStatus,
      .disallowed,
      "Should use the provided value for the default ate status"
    )
    XCTAssertFalse(
      config.advertiserIDCollectionEnabled,
      "Should use the provided value for ad ID collection"
    )
    XCTAssertTrue(
      config.eventCollectionEnabled,
      "Should use the provided value for event collection"
    )
  }

  // MARK: Coding

  func testEncodingAndDecoding() throws {
    config = AppEventsConfiguration.default()
    let decodedObject = try CodabilityTesting.encodeAndDecode(config)

    // Test Objects
    XCTAssertNotIdentical(decodedObject, config, .isCodable)
    XCTAssertEqual(decodedObject, config, .isCodable)

    // Test Properties
    XCTAssertEqual(
      config.defaultATEStatus,
      decodedObject.defaultATEStatus,
      .isCodable
    )
    XCTAssertEqual(
      config.advertiserIDCollectionEnabled,
      decodedObject.advertiserIDCollectionEnabled,
      .isCodable
    )
    XCTAssertEqual(
      config.eventCollectionEnabled,
      decodedObject.eventCollectionEnabled,
      .isCodable
    )
  }
}

extension AppEventsConfiguration {
  // swiftlint:disable:next override_in_extension
  open override func isEqual(_ object: Any?) -> Bool {
    if let other = object as? AppEventsConfiguration {
      return advertiserIDCollectionEnabled == other.advertiserIDCollectionEnabled &&
        eventCollectionEnabled == other.eventCollectionEnabled &&
        defaultATEStatus == other.defaultATEStatus
    } else {
      return super.isEqual(object)
    }
  }
}

fileprivate extension String {
  static let isCodable = "AppEventsConfiguration should be encodable and decodable"
}
