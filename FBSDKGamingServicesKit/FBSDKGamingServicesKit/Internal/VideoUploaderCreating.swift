/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol VideoUploaderCreating {
  func create(
    videoName: String,
    videoSize: UInt,
    parameters: [String: Any],
    delegate: VideoUploaderDelegate
  ) -> VideoUploading
}
