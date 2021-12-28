/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import Foundation

class TestFileHandleFactory: _FileHandleCreating {

  var stubbedFileHandle = TestFileHandler()
  var capturedURL: URL?

  func fileHandleForReading(from url: URL) throws -> _FileHandling {
    capturedURL = url

    return stubbedFileHandle
  }
}
