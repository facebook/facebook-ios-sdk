/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools

final class DialogConfigurationTests: XCTestCase {

  let coder = TestCoder()
  let versions = ["1", "2", "3"]

  enum Keys {
    static let name = "name"
    static let url = "url"
    static let versions = "appVersions"
  }

  func testSecureCoding() {
    XCTAssertTrue(
      DialogConfiguration.supportsSecureCoding,
      "Should support secure coding"
    )
  }

  func testEncodingAndDecoding() throws {
    let dialog = DialogConfiguration(
      name: name,
      url: SampleURLs.valid,
      appVersions: versions
    )
    let decodedObject = try CodabilityTesting.encodeAndDecode(dialog)

    // Test Objects
    XCTAssertNotIdentical(decodedObject, dialog, .isCodable)
    XCTAssertNotEqual(decodedObject, dialog, .isCodable) // isEqual method not set yet

    // Test Properties
    XCTAssertEqual(decodedObject.name, dialog.name, .isCodable)
    XCTAssertEqual(decodedObject.url, dialog.url, .isCodable)
    XCTAssertEqual(
      decodedObject.appVersions as? [String],
      dialog.appVersions as? [String],
      .isCodable
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "DialogConfiguration should be encodable and decodable"
}
