/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Photos
import UIKit

extension PHImageManager: MediaLibrarySearching {
  func findImage(for asset: PHAsset) throws -> UIImage {
    let options = PHImageRequestOptions()
    options.resizeMode = .exact
    options.deliveryMode = .highQualityFormat
    options.isSynchronous = true

    // Since this variable is captured by the request closure, we have to initialize it with something.
    var result: Result<UIImage, PHImageManagerSearchError> = .failure(PHImageManagerSearchError(asset: asset))

    // Since the options specify that this is a synchronous request, we are assured that this method returns only
    // after completing the request. We can thus assume that the result has been populated when we return.
    requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .default,
      options: options
    ) { potentialImage, _ in
      if let image = potentialImage {
        result = .success(image)
      } else {
        result = .failure(PHImageManagerSearchError(asset: asset))
      }
    }

    return try result.get()
  }
}

struct PHImageManagerSearchError: Error {
  let asset: PHAsset
}
