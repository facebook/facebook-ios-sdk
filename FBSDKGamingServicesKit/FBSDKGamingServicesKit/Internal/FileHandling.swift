/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol FileHandling {
  func fb_seekToEndOfFile() -> UInt64
  func fb_seek(toFileOffset offset: UInt64)
  func fb_readData(ofLength length: Int) -> Data
}
