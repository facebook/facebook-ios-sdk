/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import XCTest

final class PrivacyManifestTests: XCTestCase {
  func testTrackingDomains() {
    let bundle = Bundle(for: Hashtag.self)
    let manifestUrl = bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
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
}
