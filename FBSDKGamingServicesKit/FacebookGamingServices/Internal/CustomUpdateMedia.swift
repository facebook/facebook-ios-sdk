/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct CustomUpdateMedia: Codable, Equatable {

  var gif: FacebookGIF?
  var video: FacebookVideo?

  init?(media: URLMedia) {
    if let video = media as? FacebookVideo {
      self.video = video
      return
    }

    guard let gif = media as? FacebookGIF, self.video == nil else {
      return nil
    }
    self.gif = gif
  }
}
