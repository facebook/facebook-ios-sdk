/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Dispatch
import Photos

extension PHAsset {
  // Obtain the legacy "assets-library" URL from AVAsset
  func requestVideoURL(timeoutInMilliseconds: Int) -> URL? {
    let semaphore = DispatchSemaphore(value: 0)
    var videoURL: URL?

    let options = PHVideoRequestOptions()
    options.version = .current
    options.deliveryMode = .automatic
    options.isNetworkAccessAllowed = true

    PHImageManager.default()
      .requestAVAsset(forVideo: self, options: options) { [self] potentialAsset, _, _ in
        defer { semaphore.signal() }

        guard
          let urlAsset = potentialAsset as? AVURLAsset,
          urlAsset.url.isFileURL,
          let idTerminator = localIdentifier.firstIndex(of: "/")
        else { return }

        let id = localIdentifier.prefix(upTo: idTerminator)
        let pathExtension = urlAsset.url.pathExtension
        let path = "assets-library://asset/asset.\(pathExtension)?id=\(id)&ext=\(pathExtension)"
        videoURL = URL(string: path)
      }

    let timeout = DispatchTime.now() + .milliseconds(timeoutInMilliseconds)
    _ = semaphore.wait(timeout: timeout)

    return videoURL
  }
}
