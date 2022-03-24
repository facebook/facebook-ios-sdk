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

  // MARK: - Requesting images

  var stubbedFindImageImage: UIImage?
  var findImageAsset: PHAsset?

  func fb_findImage(for asset: PHAsset) throws -> UIImage {
    findImageAsset = asset

    struct UnstubbedImageError: Error {}
    guard let image = stubbedFindImageImage else {
      throw UnstubbedImageError()
    }

    return image
  }

  // MARK: - Getting video URLs

  var stubbedGetVideoURL: URL?
  var getVideoURLAsset: PHAsset?

  func fb_getVideoURL(for asset: PHAsset) throws -> URL {
    getVideoURLAsset = asset

    struct UnstubbedURLError: Error {}
    guard let url = stubbedGetVideoURL else {
      throw UnstubbedURLError()
    }

    return url
  }
}
