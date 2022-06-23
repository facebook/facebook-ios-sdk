/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import XCTest

final class BundleTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var bundle: Bundle!

  override func setUp() {
    super.setUp()
    bundle = Bundle(for: BundleTests.self)
  }

  override func tearDown() {
    bundle = nil
    super.tearDown()
  }

  func testInfoDictionary() throws {
    let expected = try XCTUnwrap(bundle.infoDictionary)
    let actual = try XCTUnwrap(bundle.fb_infoDictionary, .infoDictionary)

    XCTAssertEqual(
      Set(actual.keys),
      Set(expected.keys),
      .infoDictionary
    )
  }

  func testBundleIdentifier() throws {
    let bundleIdentifier = try XCTUnwrap(bundle.fb_bundleIdentifier, .bundleIdentifier)
    XCTAssertEqual(bundleIdentifier, bundle.bundleIdentifier, .bundleIdentifier)
  }

  func testIndexingInfoDictionary() throws {
    let expected = try XCTUnwrap(bundle.infoDictionary?[kCFBundleNameKey as String] as? String)

    XCTAssertEqual(
      bundle.fb_object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String,
      expected,
      .infoDictionaryIndexing
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let infoDictionary = "An info dictionary is provided through an internal abstraction"
  static let bundleIdentifier = "A bundle identifier is provided through an internal abstraction"
  static let infoDictionaryIndexing = "An info dictionary is indexed through an internal abstraction"
}
