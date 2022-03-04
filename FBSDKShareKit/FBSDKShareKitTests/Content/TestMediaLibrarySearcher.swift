/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import Photos
import UIKit

final class TestMediaLibrarySearcher: MediaLibrarySearching {
  var stubbedFindImageImage: UIImage?
  var findImageAsset: PHAsset?

  func findImage(for asset: PHAsset) throws -> UIImage {
    findImageAsset = asset

    struct UnstubbedImageError: Error {}
    guard let image = stubbedFindImageImage else {
      throw UnstubbedImageError()
    }

    return image
  }
}
