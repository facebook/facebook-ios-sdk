/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// A  tournament `score` that represents a time
struct TimeScore: Score {
  var value: TimeInterval
  var scoreType = ScoreType.time

  init(value: TimeInterval) {
    self.value = value
  }
}
