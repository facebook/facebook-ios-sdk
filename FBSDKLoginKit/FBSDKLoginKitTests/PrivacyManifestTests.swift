/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class PrivacyManifestTests: XCTestCase {
  var manifestUrl: URL?

  override func setUp() {
    super.setUp()
    let bundle = Bundle(for: LoginConfiguration.self)
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
    guard let trackingDomains = manifest?["NSPrivacyTrackingDomains"] as? NSArray else {
      return XCTFail("Could not find tracking domains")
    }
    XCTAssertTrue(trackingDomains.count == 1)
    XCTAssertTrue(trackingDomains.contains("ep1.facebook.com"))
  }

  func testRequiredReasonAPIs() {
    guard let manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    if NSDictionary(contentsOf: manifestUrl)?["NSPrivacyAccessedAPITypes"] != nil {
      return XCTFail("Should not contain Privacy Accessed API Types")
    }
  }

  func testPrivacyTracking() {
    guard let manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    let manifest = NSDictionary(contentsOf: manifestUrl)
    guard let privacyTrackingFlag = manifest?["NSPrivacyTracking"] as? Bool else {
      return XCTFail("Could not find NSPrivacyTracking key")
    }
    XCTAssertTrue(privacyTrackingFlag, "NSPrivacyTracking is expected to be true in the Privacy Manifest file")
  }
}
