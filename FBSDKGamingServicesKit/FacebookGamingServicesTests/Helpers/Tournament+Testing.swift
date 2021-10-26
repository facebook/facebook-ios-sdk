/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices

extension Tournament: Equatable {
  public static func == (lhs: Tournament, rhs: Tournament) -> Bool {
    lhs.identifier == rhs.identifier
      && lhs.score == rhs.score
      && lhs.title == rhs.title
      && lhs.expiration == rhs.expiration
      && lhs.payload == rhs.payload
  }
}
