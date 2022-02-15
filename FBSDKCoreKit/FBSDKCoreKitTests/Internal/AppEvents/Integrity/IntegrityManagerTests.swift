/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class IntegrityManagerTests: XCTestCase {

  var isGateKeeperEnabled = Bool.random()
  let gatekeeperKey = "FBSDKFeatureIntegritySample"
  let processor = TestIntegrityProcessor()
  lazy var manager = IntegrityManager(
    gateKeeperManager: TestGateKeeperManager.self,
    integrityProcessor: processor
  )

  override class func setUp() {
    super.setUp()

    TestGateKeeperManager.reset()
  }

  override func setUp() {
    super.setUp()

    TestGateKeeperManager.gateKeepers[gatekeeperKey] = isGateKeeperEnabled
  }

  override func tearDown() {
    super.tearDown()

    TestGateKeeperManager.reset()
  }

  func testCreating() {
    XCTAssertTrue(
      manager.gateKeeperManager is TestGateKeeperManager.Type,
      "Should use the provided gatekeeper manager"
    )
    XCTAssertEqual(
      ObjectIdentifier(manager.integrityProcessor!), // swiftlint:disable:this force_unwrapping
      ObjectIdentifier(processor),
      "Should use the provided integrity processor"
    )
    XCTAssertFalse(
      manager.isIntegrityEnabled,
      "Should not enable integrity checks by default"
    )
    XCTAssertFalse(
      manager.isSampleEnabled,
      "Should not enable sampling by default"
    )
  }

  func testEnabling() {
    manager.enable()

    XCTAssertTrue(
      manager.isIntegrityEnabled,
      "Enabling should enable integrity checks"
    )
    XCTAssertEqual(
      manager.isSampleEnabled,
      isGateKeeperEnabled,
      "Enabling should set sampling to the value provided by the gatekeeper manager"
    )
  }

  // MARK: - Processing

  func testProcessingParametersWithRestrictedData() throws {
    manager.enable()

    let parameters: [AppEvents.ParameterName: String] = [
      .init("address"): "2301 N Highland Ave, Los Angeles, CA 90068", // address
      .init("period_starts"): "2020-02-03", // health
    ]

    processor.stubbedParameters = [
      "address": true,
      "period_starts": true,
    ]

    let processed = try XCTUnwrap(
      manager.processParameters(parameters, eventName: .init(name)) as? [AppEvents.ParameterName: String],
      "Processed parameters should be in the expected format"
    )

    XCTAssertNil(processed[.init("address")])
    XCTAssertNil(processed[.init("period_starts")])
    let onDeviceParams = try XCTUnwrap(
      processed[.init("_onDeviceParams")],
      "Should have the expected processed on-device parameters"
    )
    XCTAssertTrue(
      onDeviceParams.contains("address")
    )
    XCTAssertTrue(
      onDeviceParams.contains("period_starts")
    )
  }

  func testProcessingParametersWithNonRestrictedData() throws {
    manager.enable()

    let parameters: [AppEvents.ParameterName: Any] = [
      .init("_valueToSum"): 1,
      .init("_session_id"): "12345",
    ]
    processor.stubbedParameters = [
      "_valueToSum": false,
      "_session_id": false,
    ]
    let processed = try XCTUnwrap(
      manager.processParameters(parameters, eventName: .init(name)),
      "Processed parameters should be in the expected format"
    )

    XCTAssertNotNil(processed[.init("_valueToSum")])
    XCTAssertNotNil(processed[.init("_session_id")])
    XCTAssertNil(processed[.init("_onDeviceParams")])
  }
}
