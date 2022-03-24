/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Photos
import UIKit

// This protocol represents an abstraction layer for an extension on an external API,
// so its methods must start with "fb_" to safeguard against potential conflicts with the API.
protocol MediaLibrarySearching {
  func fb_findImage(for asset: PHAsset) throws -> UIImage
  func fb_getVideoURL(for asset: PHAsset) throws -> URL
}
