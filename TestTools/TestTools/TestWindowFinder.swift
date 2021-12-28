/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
public class TestWindowFinder: NSObject, WindowFinding {
  public var wasFindWindowCalled = false
  public var window: UIWindow?

  public convenience init(window: UIWindow) {
    self.init()

    self.window = window
  }

  public func findWindow() -> UIWindow? {
    wasFindWindowCalled = true
    return window
  }
}
