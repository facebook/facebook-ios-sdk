/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit_Basics

import XCTest

final class PrivacyManifestTests: XCTestCase {
  func testTrackingDomains() {
    let bundle = Bundle(for: BasicUtility.self)
    let manifestUrl = bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
    guard let manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    let manifest = NSDictionary(contentsOf: manifestUrl)
    if manifest?["NSPrivacyTrackingDomains"] is NSArray {
      XCTFail("Should not contain tracking domains")
    }
  }
}
