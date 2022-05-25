/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

struct IdentifiedLoginResultHandler: Equatable {
  private let identifier = UUID()
  private let closure: (_ result: LoginManagerLoginResult?, _ error: Error?) -> Void

  init(_ closure: @escaping (_ result: LoginManagerLoginResult?, _ error: Error?) -> Void) {
    self.closure = closure
  }

  func callAsFunction(_ result: LoginManagerLoginResult?, _ error: Error?) {
    closure(result, error)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier
  }
}

#endif
