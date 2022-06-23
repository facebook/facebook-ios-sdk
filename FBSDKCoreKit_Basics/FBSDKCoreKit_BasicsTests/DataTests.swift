/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import XCTest

final class DataTests: XCTestCase {
  func testReadingContentsOfFile() throws {
    let path = try XCTUnwrap(String.sampleFilePath)
    let actual = try NSData.fb_data(withContentsOfFile: path)
    let expected = try XCTUnwrap(NSData(contentsOfFile: path)) as Data

    XCTAssertEqual(actual, expected, .readContentsOfFile)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let readContentsOfFile = "Data can be read from the contents of a file through an internal abstraction"
}

// MARK: - Test Values

fileprivate extension String {
  static let sampleFilePath = Bundle(for: DataTests.self).path(forResource: "Sample", ofType: "txt")
}
