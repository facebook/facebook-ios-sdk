/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol KeychainPersisting {
  func save(data: Data) -> OSStatus
  func read() -> KeychainResult
  func delete() -> OSStatus
}
