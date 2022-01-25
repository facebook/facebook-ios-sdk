/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol FileHandling {
  func seekToEndOfFile() -> UInt64
  func seek(toFileOffset offset: UInt64)
  func readData(ofLength length: Int) -> Data
}

extension FileHandle: FileHandling {}
