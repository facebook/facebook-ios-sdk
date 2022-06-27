/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import Foundation
import XCTest

@available(iOS 13.4, *)
final class FileHandleTests: XCTestCase {
  // swiftlint:disable:next implicitly_unwrapped_optional
  var fileHandle: FileHandle!

  override func setUp() async throws {
    try await super.setUp()

    let path = try XCTUnwrap(Bundle(for: FileHandleTests.self).path(forResource: "Sample", ofType: "txt"))
    fileHandle = try XCTUnwrap(FileHandle(forReadingAtPath: path))
  }

  override func tearDown() async throws {
    try fileHandle.close()
    fileHandle = nil

    try await super.tearDown()
  }

  func testSeekingToEndOfFile() throws {
    let expectedFileSize = try fileHandle.seekToEnd()
    let actualFileSize = fileHandle.fb_seekToEndOfFile()

    XCTAssertEqual(actualFileSize, expectedFileSize, .seekToEnd)
  }

  func testSeekingToFileOffset() throws {
    try fileHandle.seek(toOffset: 4)
    let expectedOffset = try fileHandle.offset()
    fileHandle.fb_seek(toFileOffset: 4)
    let actualOffset = try fileHandle.offset()

    XCTAssertEqual(actualOffset, expectedOffset, .seekToOffset)
  }

  func testReadingData() throws {
    let expectedData = try fileHandle.read(upToCount: 6)
    try fileHandle.seek(toOffset: 0)
    let actualData = fileHandle.fb_readData(ofLength: 6)

    XCTAssertEqual(actualData, expectedData, .readData)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let seekToEnd = "A file handle can seek to the end of the file through an internal abstraction"
  static let seekToOffset = "A file handle can seek to an offset through an internal abstraction"
  static let readData = "A file handle can read data through an internal abstraction"
}
