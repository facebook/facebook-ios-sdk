/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol DataPersisting {
  func save(_ data: Data) throws
  func read() throws -> Data
  func delete() throws
}
