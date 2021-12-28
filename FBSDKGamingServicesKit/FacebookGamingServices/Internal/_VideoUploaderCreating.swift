/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(_FBSDKVideoUploaderCreating)
public protocol _VideoUploaderCreating {
  func create(
    videoName: String,
    videoSize: UInt,
    parameters: [String: Any],
    delegate: _VideoUploaderDelegate
  ) -> _VideoUploading
}
