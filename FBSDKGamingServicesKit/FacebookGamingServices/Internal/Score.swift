/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// A protocol used to create a new score type that can be used to update a tournament
protocol Score {
  associatedtype DataType

  var value: DataType { get }
  var scoreType: ScoreType { get }
}
