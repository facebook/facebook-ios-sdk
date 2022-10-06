/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension FileHandle: FileHandling {
  func fb_seekToEndOfFile() -> UInt64 {
    seekToEndOfFile()
  }

  func fb_seek(toFileOffset offset: UInt64) {
    seek(toFileOffset: offset)
  }

  func fb_readData(ofLength length: Int) -> Data {
    readData(ofLength: length)
  }
}
