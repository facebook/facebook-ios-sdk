/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct ContentFlags {
  var containsMedia: Bool
  var containsPhotos: Bool
  var containsVideos: Bool

  init(
    containsMedia: Bool = false,
    containsPhotos: Bool = false,
    containsVideos: Bool = false
  ) {
    self.containsMedia = containsMedia
    self.containsPhotos = containsPhotos
    self.containsVideos = containsVideos
  }

  var containsAllTypes: Bool {
    containsMedia && containsPhotos && containsVideos
  }

  static func |= (lhs: inout Self, rhs: Self) {
    lhs = ContentFlags(
      containsMedia: lhs.containsMedia || rhs.containsMedia,
      containsPhotos: lhs.containsPhotos || rhs.containsPhotos,
      containsVideos: lhs.containsVideos || rhs.containsVideos
    )
  }
}
