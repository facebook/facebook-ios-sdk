/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public struct FacebookVideo: Codable, Equatable, URLMedia {
  var url: URL

  /**
   Initializer for a video url media

   - Parameters:
   - url: The url that represents the video on the facebook platform
   */
  public init(withUrl url: URL) {
    self.url = url
  }
}
