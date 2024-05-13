/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class PrivacyManifestTests: XCTestCase {
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testTrackingDomains() {
    let bundle = Bundle(for: Settings.self)
    let manifestUrl = bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
    guard let manifestUrl = manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    let manifest = NSDictionary(contentsOf: manifestUrl)
    guard let trackingDomains = manifest?["NSPrivacyTrackingDomains"] as? NSArray else {
      return XCTFail("Could not find tracking domains")
    }
    XCTAssertTrue(trackingDomains.count == 1)
    XCTAssertTrue(trackingDomains.contains("ep1.facebook.com"))
  }
}
