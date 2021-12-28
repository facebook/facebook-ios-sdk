/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

import Foundation

class TestFileManager: FileManaging {
  var removeItemAtPathWasCalled = false
  var contentsOfDirectoryAtPathWasCalled = false
  var capturedFileExistsAtPath: String?
  var capturedCreateDirectoryPath: String?
  var stubbedContentsOfDirectory = [String]()
  var stubbedFileExists = true
  var stubbedCreateDirectoryShouldSucceed = true

  var tempDirectoryURL: URL?

  init(tempDirectoryURL: URL? = nil) {
    self.tempDirectoryURL = tempDirectoryURL
  }

  func url(
    for directory: FileManager.SearchPathDirectory,
    in domain: FileManager.SearchPathDomainMask,
    appropriateFor url: URL,
    create shouldCreate: Bool
  ) throws -> URL {
    guard let url = tempDirectoryURL else {
      throw SampleError()
    }

    return url
  }

  func createDirectory(
    atPath path: String,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]? = [:]
  ) throws {
    capturedCreateDirectoryPath = path
    if !stubbedCreateDirectoryShouldSucceed {
      throw SampleError()
    }
  }

  func fileExists(atPath path: String) -> Bool {
    capturedFileExistsAtPath = path
    return stubbedFileExists
  }

  func contentsOfDirectory(atPath path: String, error: NSErrorPointer) -> [String] {
    contentsOfDirectoryAtPathWasCalled = true

    return stubbedContentsOfDirectory
  }

  func removeItem(atPath path: String) throws {
    removeItemAtPathWasCalled = true
  }
}
