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

  func testCreatingWithDefaultIAPDedupWindow() {
    XCTAssertEqual(configuration.iapManualAndAutoLogDedupWindow, 60000)
  }

  func testCreatingWithKnownIAPDedupWindow() {
    configuration = SampleAppEventsConfigurations.create(iapManualAndAutoLogDedupWindow: 30000)
    XCTAssertEqual(configuration.iapManualAndAutoLogDedupWindow, 30000)
  }

  func testCreatingWithDefaultIAPProdDedupConfiguration() {
    let expectedConfig = [
      "fb_content_id": ["fb_content_id"],
      "fb_content_title": ["fb_content_title"],
      "fb_description": ["fb_description"],
      "fb_transaction_id": ["fb_transaction_id"],
      "_valueToSum": ["_valueToSum"],
      "fb_currency": ["fb_currency"],
    ]
    XCTAssertEqual(configuration.iapProdDedupConfiguration, expectedConfig)
  }

  func testCreatingWithKnownIAPProdDedupConfiguration() {
    let config = [
      "key_1": ["val_1"],
      "key_2": ["val_2"],
    ]
    configuration = SampleAppEventsConfigurations.create(iapProdDedupConfiguration: config)
    XCTAssertEqual(configuration.iapProdDedupConfiguration, config)
  }

  func testCreatingWithDefaultIAPTestDedupConfiguration() {
    XCTAssertTrue(configuration.iapTestDedupConfiguration.isEmpty)
  }

  func testCreatingWithKnownIAPTestDedupConfiguration() {
    let config = [
      "key_1": ["val_1"],
      "key_2": ["val_2"],
    ]
    configuration = SampleAppEventsConfigurations.create(iapTestDedupConfiguration: config)
    XCTAssertEqual(configuration.iapTestDedupConfiguration, config)
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
    XCTAssertEqual(
      configuration.iapProdDedupConfiguration,
      SampleAppEventsConfigurations.default.iapProdDedupConfiguration
    )
    XCTAssertEqual(
      configuration.iapTestDedupConfiguration,
      SampleAppEventsConfigurations.default.iapTestDedupConfiguration
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
    let expectedProdConfig = [
      "fb_content_id": ["fb_content_id", "fb_product_item_id"],
      "fb_transaction_id": ["fb_transaction_id", "fb_order_id"],
    ]
    let expectedTestConfig = [
      "test_key_1": ["test_value_0", "test_value_1"],
    ]
    XCTAssertEqual(configuration.iapProdDedupConfiguration, expectedProdConfig)
    XCTAssertEqual(configuration.iapTestDedupConfiguration, expectedTestConfig)
  }

  func testCreatingWithEmptyDedupConfig() {
    configuration = _AppEventsConfiguration(json: RawAppEventsConfigurationResponseFixtures.emptyDedupConfig)
    XCTAssertEqual(
      configuration.iapProdDedupConfiguration,
      SampleAppEventsConfigurations.default.iapProdDedupConfiguration
    )
    XCTAssertEqual(
      configuration.iapTestDedupConfiguration,
      SampleAppEventsConfigurations.default.iapTestDedupConfiguration
    )
  }

  func testCreatingWithEmptyProdAndTestDedupConfig() {
    configuration = _AppEventsConfiguration(json: RawAppEventsConfigurationResponseFixtures.emptyProdAndTestDedupConfig)
    XCTAssertTrue(configuration.iapProdDedupConfiguration.isEmpty)
    XCTAssertTrue(configuration.iapTestDedupConfiguration.isEmpty)
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
    XCTAssertEqual(
      configuration.iapManualAndAutoLogDedupWindow,
      decodedObject.iapManualAndAutoLogDedupWindow,
      .isCodable
    )
    XCTAssertEqual(
      configuration.iapProdDedupConfiguration,
      decodedObject.iapProdDedupConfiguration,
      .isCodable
    )
    XCTAssertEqual(
      configuration.iapTestDedupConfiguration,
      decodedObject.iapTestDedupConfiguration,
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
        iapObservationTime == other.iapObservationTime &&
        iapManualAndAutoLogDedupWindow == other.iapManualAndAutoLogDedupWindow &&
        iapProdDedupConfiguration == other.iapProdDedupConfiguration &&
        iapTestDedupConfiguration == other.iapTestDedupConfiguration
    } else {
      return super.isEqual(object)
    }
  }
}

fileprivate extension String {
  static let isCodable = "_AppEventsConfiguration should be encodable and decodable"
}
