/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

class FileHandleFactory: NSObject, _FileHandleCreating {
  func fileHandleForReading(from url: URL) throws -> _FileHandling {
    try FileHandle(forReadingFrom: url)
  }
}
