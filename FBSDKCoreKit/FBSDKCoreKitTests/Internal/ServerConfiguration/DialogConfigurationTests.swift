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

  func testEncoding() {
    let dialog = DialogConfiguration(
      name: name,
      url: SampleURLs.valid,
      appVersions: versions
    )

    dialog.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject[Keys.name] as? String,
      name,
      "Should encode the dialog name with the expected key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.url] as? URL,
      SampleURLs.valid,
      "Should encode the dialog url with the expected key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.versions] as? [String],
      versions,
      "Should encode the dialog app versions with the expected key"
    )
  }

  func testDecoding() {
    _ = DialogConfiguration(coder: coder)

    XCTAssertTrue(
      coder.decodedObject[Keys.name] is NSString.Type,
      "Should attempt to decode the name as a string"
    )
    XCTAssertTrue(
      coder.decodedObject[Keys.url] is NSURL.Type,
      "Should attempt to decode the url as a URL"
    )
    XCTAssertTrue(
      coder.decodedObject[Keys.versions] is NSSet,
      "Should attempt to decode the versions as a set of strings"
    )
  }
}
