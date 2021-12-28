/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(_FBSDKVideoUploaderFactory)
public class _VideoUploaderFactory: NSObject, _VideoUploaderCreating {
  public func create(
    videoName: String,
    videoSize: UInt,
    parameters: [String: Any],
    delegate: _VideoUploaderDelegate
  ) -> _VideoUploading {
    _VideoUploader(
      videoName: videoName,
      videoSize: videoSize,
      parameters: parameters,
      delegate: delegate
    )
  }
}
