/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension AsyncSequence {
  func getValues() async rethrows -> [Element] {
    var result: [Element] = []
    for try await element in self {
      if Task.isCancelled { break }
      result.append(element)
    }
    return result
  }
}
