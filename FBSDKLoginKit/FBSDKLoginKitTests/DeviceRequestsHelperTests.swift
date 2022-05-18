/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class DeviceRequestsHelperTests: XCTestCase, NetServiceDelegate {

  func testGetDeviceInfo() throws {
    let currentDeviceInfo = try XCTUnwrap(getCurrentDeviceInfo())
    XCTAssertEqual(_DeviceRequestsHelper.getDeviceInfo(), currentDeviceInfo, .hasEqualDeviceInfo)
  }

  func testStartAdvertisementService() {
    XCTAssertTrue(
      _DeviceRequestsHelper.startAdvertisementService(loginCode: "123", delegate: self),
      .startsAdvertisementService
    )
    XCTAssertGreaterThan(_DeviceRequestsHelper.mdnsAdvertisementServices.count, 0, .hasAddedService)
  }

  func testIsDelegateForAdvertisementService() throws {
    _DeviceRequestsHelper.startAdvertisementService(loginCode: "123", delegate: self)
    let services = _DeviceRequestsHelper.mdnsAdvertisementServices
    let service = try XCTUnwrap(services.object(forKey: self) as? NetService, .isDelegateForService)

    XCTAssertTrue(_DeviceRequestsHelper.isDelegate(self, forAdvertisementService: service), .isDelegateForService)
  }

  func testCleanUpAdvertisementService() {
    _DeviceRequestsHelper.startAdvertisementService(loginCode: "123", delegate: self)
    XCTAssertGreaterThan(_DeviceRequestsHelper.mdnsAdvertisementServices.count, 0, .hasAddedService)
    _DeviceRequestsHelper.cleanUpAdvertisementService(for: self)
    XCTAssertEqual(_DeviceRequestsHelper.mdnsAdvertisementServices.count, 0, .hasRemoveService)
  }

  // MARK: - Helpers

  private func getCurrentDeviceInfo() -> String? {
    let model = UIDevice.current.model

    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in String(validatingUTF8: ptr) }
    }

    guard let device = modelCode else { return nil }

    return """
      {"model":"\(model)","device":"\(device)"}
      """
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let hasEqualDeviceInfo = "Device info represents current device"
  static let startsAdvertisementService = "advertisement service starts with the login code provided"
  static let hasAddedService = "service is added to the collection of services"
  static let hasRemoveService = "service is removed from the collection of services"
  static let isDelegateForService = "service matches the service from the passed delegate"
}
