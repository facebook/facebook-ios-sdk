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
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testTrackingDomains() {
    let bundle = Bundle(for: AEMConfiguration.self)
    let manifestUrl = bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
    guard let manifestUrl = manifestUrl else {
      return XCTFail("Could not find Privacy Manifest file")
    }
    let manifest = NSDictionary(contentsOf: manifestUrl)
    guard manifest?["NSPrivacyTrackingDomains"] is NSArray else {
      return
    }
    return XCTFail("Should not contain tracking domains")
  }
}
