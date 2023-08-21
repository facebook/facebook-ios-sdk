/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import Foundation

final class TestFileHandleFactory: FileHandleCreating {

  var stubbedFileHandle = TestFileHandler()
  var capturedURL: URL?

  func fileHandleForReading(from url: URL) throws -> FileHandling {
    capturedURL = url

    return stubbedFileHandle
  }
}
