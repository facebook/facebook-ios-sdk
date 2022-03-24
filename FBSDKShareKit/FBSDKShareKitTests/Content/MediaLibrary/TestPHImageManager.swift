/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Photos
import UIKit

// This test double simply subclasses `PHImageManager` in order to capture calls to itself
final class TestPHImageManager: PHImageManager {

  // MARK: - Requesting images

  var requestImageAsset: PHAsset?
  var requestImageTargetSize: CGSize?
  var requestImageContentMode: PHImageContentMode?
  var requestImageOptions: PHImageRequestOptions?
  var stubbedRequestImageImage: UIImage?
  var stubbedRequestImageInfo: [AnyHashable: Any]?

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

    resultHandler(stubbedRequestImageImage, stubbedRequestImageInfo)

    return PHImageRequestID(14)
  }

  // MARK: - Getting video URLs

  typealias RequestAVAssetResultHandler = (AVAsset?, AVAudioMix?, [AnyHashable: Any]?) -> Void

  var requestAVAssetAsset: PHAsset?
  var requestAVAssetOptions: PHVideoRequestOptions?
  var stubbedGetVideoURLAsset: AVAsset?
  var stubbedGetVideoURLAudioMix: AVAudioMix?
  var stubbedGetVideoURLInfo: [AnyHashable: Any]?

  override func requestAVAsset(
    forVideo asset: PHAsset,
    options: PHVideoRequestOptions?,
    resultHandler: @escaping RequestAVAssetResultHandler
  ) -> PHImageRequestID {
    requestAVAssetAsset = asset
    requestAVAssetOptions = options

    resultHandler(
      stubbedGetVideoURLAsset,
      stubbedGetVideoURLAudioMix,
      stubbedGetVideoURLInfo
    )

    return PHImageRequestID(14)
  }
}
