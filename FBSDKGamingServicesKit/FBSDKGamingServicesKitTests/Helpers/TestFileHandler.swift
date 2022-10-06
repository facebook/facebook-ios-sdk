/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import Foundation

final class TestFileHandler: FileHandling {
  var stubbedReadData = Data()
  var stubbedSeekToEndOfFile: UInt64 = 0
  var capturedFileOffset: UInt64 = 0

  func fb_seekToEndOfFile() -> UInt64 {
    stubbedSeekToEndOfFile
  }

  func fb_seek(toFileOffset offset: UInt64) {
    capturedFileOffset = offset
  }

  func fb_readData(ofLength length: Int) -> Data {
    stubbedReadData
  }
}
