/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public final class TestInternalURLOpener: NSObject, _InternalURLOpener {
  var capturedOpenURL: URL?
  var capturedCanOpenURL: URL?
  var canOpenURL: Bool
  var capturedOpenURLCompletion: ((Bool) -> Void)?

  init(canOpenURL: Bool = false) {
    self.canOpenURL = canOpenURL
  }

  public func canOpen(_ url: URL) -> Bool {
    capturedCanOpenURL = url
    return canOpenURL
  }

  public func open(_ url: URL) -> Bool {
    capturedOpenURL = url
    return true
  }

  public func open(
    _ url: URL,
    options: [UIApplication.OpenExternalURLOptionsKey: Any],
    completionHandler completion: ((Bool) -> Void)?
  ) {
    capturedOpenURL = url
    capturedOpenURLCompletion = completion
  }
}
