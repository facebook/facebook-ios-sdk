/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Photos

final class TestPHAsset: PHAsset {
  var stubbedMediaType: PHAssetMediaType?

  override var mediaType: PHAssetMediaType {
    stubbedMediaType ?? super.mediaType
  }
}
