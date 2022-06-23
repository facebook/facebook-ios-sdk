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

final class TestFileManager: FileManaging {
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

  func fb_createDirectory(
    atPath path: String,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]? = [:]
  ) throws {
    capturedCreateDirectoryPath = path
    if !stubbedCreateDirectoryShouldSucceed {
      throw SampleError()
    }
  }

  func fb_fileExists(atPath path: String) -> Bool {
    capturedFileExistsAtPath = path
    return stubbedFileExists
  }

  func fb_contentsOfDirectory(atPath path: String) throws -> [String] {
    contentsOfDirectoryAtPathWasCalled = true

    return stubbedContentsOfDirectory
  }

  func fb_removeItem(atPath path: String) throws {
    removeItemAtPathWasCalled = true
  }
}
