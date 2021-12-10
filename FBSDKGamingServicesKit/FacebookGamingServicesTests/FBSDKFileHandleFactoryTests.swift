/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import XCTest

class FBSDKFileHandleFactoryTests: XCTestCase {

  func testCreatingFileHandle() throws {
    let data = "foo".data(using: .utf8)
    let url = URL(
      fileURLWithPath: NSTemporaryDirectory(),
      isDirectory: true
    ).appendingPathComponent(name)

    FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)

    XCTAssertNotNil(
      try? _FileHandleFactory().fileHandleForReading(from: url),
      "A file handle factory should be able to return a handle to a valid file"
    )
  }
}
