/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Makes sure no other thread reenters the closure before the one running has not returned
 */
func synchronized(_ lock: AnyObject, closure: () throws -> Void) rethrows {
  objc_sync_enter(lock)
  defer { objc_sync_exit(lock) }
  try closure()
}
