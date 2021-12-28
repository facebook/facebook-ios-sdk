/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

extension Tournament: Equatable {
  public static func == (lhs: Tournament, rhs: Tournament) -> Bool {
    lhs.identifier == rhs.identifier
      && lhs.title == rhs.title
      && lhs.endTime == rhs.endTime
      && lhs.payload == rhs.payload
  }
}
