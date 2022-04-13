/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum NonceValidator {
  static func isValid(nonce: String) -> Bool {
    guard !nonce.isEmpty else { return false }

    return nonce.rangeOfCharacter(from: .whitespaces) == nil
  }
}
