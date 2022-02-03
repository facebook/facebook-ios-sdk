/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum GamingServiceType {
  case friendFinder
  case mediaAsset
  case community

  var urlPath: String {
    switch self {
    case .friendFinder:
      return "friendfinder"
    case .mediaAsset:
      return "media_asset"
    case .community:
      return "community"
    }
  }
}
