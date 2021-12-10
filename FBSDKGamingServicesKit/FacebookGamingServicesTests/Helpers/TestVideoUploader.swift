/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import Foundation

class TestVideoUploader: VideoUploading {

  var delegate: VideoUploaderDelegate?
  var wasStartCalled = false

  func start() {
    wasStartCalled = true
  }
}
