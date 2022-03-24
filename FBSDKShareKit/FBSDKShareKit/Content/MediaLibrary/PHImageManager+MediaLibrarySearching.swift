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
  struct MediaLibrarySearchError: Error {
    let asset: PHAsset
  }

  func fb_findImage(for asset: PHAsset) throws -> UIImage {
    let options = PHImageRequestOptions()
    options.resizeMode = .exact
    options.deliveryMode = .highQualityFormat
    options.isSynchronous = true

    // Since this variable is captured by the request closure, we have to initialize it with something.
    var result: Result<UIImage, MediaLibrarySearchError> = .failure(.init(asset: asset))

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
        result = .failure(MediaLibrarySearchError(asset: asset))
      }
    }

    return try result.get()
  }

  func fb_getVideoURL(for videoAsset: PHAsset) throws -> URL {
    let semaphore = DispatchSemaphore(value: 0)
    var url: URL?

    let options = PHVideoRequestOptions()
    options.version = .current
    options.deliveryMode = .automatic
    options.isNetworkAccessAllowed = true

    requestAVAsset(forVideo: videoAsset, options: options) { potentialAsset, _, _ in
      defer { semaphore.signal() }

      guard
        let urlAsset = potentialAsset as? AVURLAsset,
        urlAsset.url.isFileURL,
        let idTerminator = videoAsset.localIdentifier.firstIndex(of: "/")
      else { return }

      let id = videoAsset.localIdentifier.prefix(upTo: idTerminator)
      let pathExtension = urlAsset.url.pathExtension
      let path = "assets-library://asset/asset.\(pathExtension)?id=\(id)&ext=\(pathExtension)"
      url = URL(string: path)
    }

    let timeout = DispatchTime.now() + .milliseconds(500)
    _ = semaphore.wait(timeout: timeout)

    if let url = url {
      return url
    } else {
      throw MediaLibrarySearchError(asset: videoAsset)
    }
  }
}
