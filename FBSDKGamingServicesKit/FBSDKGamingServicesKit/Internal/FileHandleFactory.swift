/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class FileHandleFactory: NSObject, FileHandleCreating {
  func fileHandleForReading(from url: URL) throws -> FileHandling {
    try FileHandle(forReadingFrom: url)
  }
}
