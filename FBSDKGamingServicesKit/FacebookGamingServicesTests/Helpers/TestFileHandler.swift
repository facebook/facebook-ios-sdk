/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import Foundation

class TestFileHandler: _FileHandling {
  var stubbedReadData = Data()
  var stubbedSeekToEndOfFile: UInt64 = 0
  var capturedFileOffset: UInt64 = 0

  func seekToEndOfFile() -> UInt64 {
    stubbedSeekToEndOfFile
  }

  func seek(toFileOffset offset: UInt64) {
    capturedFileOffset = offset
  }

  func readData(ofLength length: Int) -> Data {
    stubbedReadData
  }
}
