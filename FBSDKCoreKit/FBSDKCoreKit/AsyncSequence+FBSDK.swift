/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@available(iOS 13.0, *)
extension AsyncSequence {
  func getValues() async rethrows -> [Element] {
    return try await reduce(into: []) { // swiftlint:disable:this implicit_return
      $0.append($1)
    }
  }
}
