/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit

import XCTest

final class PrivacyManifestTests: XCTestCase {
  var manifestUrl: URL?

  override func setUp() {
    super.setUp()
    let bundle = Bundle(for: AEMConfiguration.self)
    manifestUrl = bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
  }

  override func tearDown() {
    manifestUrl = nil
    super.tearDown()
  }

  func testTrackingDomains() {
    guard let manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    let manifest = NSDictionary(contentsOf: manifestUrl)
    if manifest?["NSPrivacyTrackingDomains"] is NSArray {
      XCTFail("Should not contain tracking domains")
    }
  }

  func testRequiredReasonAPIs() {
    guard let manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    let manifest = NSDictionary(contentsOf: manifestUrl)
    guard let rrAPIs = manifest?["NSPrivacyAccessedAPITypes"] as? NSArray else {
      return XCTFail("Could not find Privacy Accessed API Types")
    }
    XCTAssertTrue(rrAPIs.count == 1, "Should only expect to have one API in the Privacy Manifest file")
    guard let rrAPIDict = rrAPIs[0] as? NSDictionary else {
      return XCTFail("Could not find items in Privacy Accessed API Types")
    }

    XCTAssertEqual(
      rrAPIDict["NSPrivacyAccessedAPIType"] as? String,
      "NSPrivacyAccessedAPICategoryUserDefaults",
      "Should match UserDefaults category"
    )
    guard let reasons = rrAPIDict["NSPrivacyAccessedAPITypeReasons"] as? NSArray else {
      return XCTFail("Could not find Privacy Accessed API Reasons")
    }
    XCTAssertTrue(
      reasons.count == 1,
      """
      Should only expect to have one reason for UserDefaults
      in the Privacy Manifest file
      """
    )
    XCTAssertEqual(reasons[0] as? String, "CA92.1", "Reason should match CA92.1")
  }

  func testPrivacyTracking() {
    guard let manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    let manifest = NSDictionary(contentsOf: manifestUrl)
    guard let privacyTrackingFlag = manifest?["NSPrivacyTracking"] as? Bool else {
      return XCTFail("Could not find NSPrivacyTracking key")
    }
    XCTAssertFalse(privacyTrackingFlag, "NSPrivacyTracking is expected to be true in the Privacy Manifest file")
  }
}
