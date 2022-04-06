/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import Foundation

final class TestInternalURLOpener: NSObject, ShareInternalURLOpening {

  var canOpenURL = false
  var computeCanOpenURL: ((URL) -> Bool)?

  func canOpenURL(_ url: URL) -> Bool {
    computeCanOpenURL?(url) ?? canOpenURL
  }
}
