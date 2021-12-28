/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestControl: UIControl {
  var capturedAction: Selector?
  var stubbedWindow: UIWindow?

  override var window: UIWindow? {
    stubbedWindow
  }

  override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
    capturedAction = action
  }
}
