/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public struct FacebookGIF: Codable, Equatable, URLMedia {
  var url: URL

  /**
   Initializer for a gif url media

    - Parameters:
     - url: The url that represents the gif on the facebook platform
    */
  public init(withUrl url: URL) {
    self.url = url
  }
}
