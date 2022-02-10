/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import Foundation

final class TestVideoUploader: VideoUploading {

  var delegate: VideoUploaderDelegate?
  var wasStartCalled = false

  func start() {
    wasStartCalled = true
  }
}
