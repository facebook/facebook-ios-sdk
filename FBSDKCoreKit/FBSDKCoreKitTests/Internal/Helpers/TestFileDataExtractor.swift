/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

import Foundation

class TestFileDataExtractor: FileDataExtracting {
  static var stubbedData: Data?
  static var capturedFileNames = [String]()

  static func data(
    withContentsOfFile path: String,
    options readOptionsMask: NSData.ReadingOptions = []
  ) throws -> Data {
    capturedFileNames.append(path)
    guard let data = stubbedData else {
      throw SampleError()
    }
    return data
  }

  static func reset() {
    capturedFileNames = []
  }
}
