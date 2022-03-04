/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Photos
import UIKit

final class TestPHImageManager: PHImageManager {
  var requestImageAsset: PHAsset?
  var requestImageTargetSize: CGSize?
  var requestImageContentMode: PHImageContentMode?
  var requestImageOptions: PHImageRequestOptions?
  var stubbedRequestedImage: UIImage?

  override func requestImage(
    for asset: PHAsset,
    targetSize: CGSize,
    contentMode: PHImageContentMode,
    options: PHImageRequestOptions?,
    resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void
  ) -> PHImageRequestID {
    requestImageAsset = asset
    requestImageTargetSize = targetSize
    requestImageContentMode = contentMode
    requestImageOptions = options

    resultHandler(stubbedRequestedImage, nil)

    return PHImageRequestID(14)
  }
}
