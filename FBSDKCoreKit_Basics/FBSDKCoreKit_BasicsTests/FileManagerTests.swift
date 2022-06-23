/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import XCTest

@available(iOS 13, *)
final class FileManagerTests: XCTestCase {
  override func setUp() async throws {
    try await super.setUp()

    try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
  }

  override func tearDown() async throws {
    try FileManager.default.removeItem(at: testDirectory)

    try await super.tearDown()
  }

  func testCreatingDirectory() throws {
    try FileManager.default.fb_createDirectory(
      atPath: sampleDirectory.path,
      withIntermediateDirectories: true,
      attributes: nil
    )

    var isDirectory: ObjCBool = false
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: sampleDirectory.path, isDirectory: &isDirectory),
      .createDirectory
    )
    XCTAssertTrue(isDirectory.boolValue, .createDirectory)
  }

  func testCheckingFileExistence() throws {
    try Data.sample.write(to: sampleFile)

    XCTAssertTrue(
      FileManager.default.fb_fileExists(atPath: sampleFile.path),
      .checkFileExistence
    )
  }

  func testRemovingItem() throws {
    try Data.sample.write(to: sampleFile)

    try FileManager.default.fb_removeItem(atPath: sampleFile.path)

    XCTAssertFalse(
      FileManager.default.fileExists(atPath: sampleFile.path),
      .removeItem
    )
  }

  func testReadingDirectoryContents() throws {
    try Data.sample.write(to: sampleFile)
    let expected = try FileManager.default.contentsOfDirectory(atPath: testDirectory.path)
    let actual = try FileManager.default.fb_contentsOfDirectory(atPath: testDirectory.path)

    XCTAssertEqual(actual, expected, .readDirectoryContents)
  }

  // MARK: - Helpers

  private let testDirectoryName = UUID().uuidString

  private var testDirectory: URL {
    FileManager.default
      .temporaryDirectory
      .appendingPathComponent(testDirectoryName, isDirectory: true)
  }

  private var sampleFile: URL {
    testDirectory.appendingPathComponent(.sampleFilename, isDirectory: false)
  }

  private var sampleDirectory: URL {
    testDirectory.appendingPathComponent(.sampleDirectoryName, isDirectory: true)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let createDirectory = "A directory can be created through an internal abstraction"
  static let checkFileExistence = "A file's existence can be checked through an internal abstraction"
  static let removeItem = "An item can be removed through an internal abstraction"
  static let readDirectoryContents = "A directory's contents can be read through an internal abstraction"
}

// MARK: - Test Values

fileprivate extension String {
  static let sampleFilename = "Sample.txt"
  static let sampleDirectoryName = "sample1/sample2"
}

fileprivate extension Data {
  static let sample = "sample text".data(using: .utf8)! // swiftlint:disable:this force_unwrapping
}
