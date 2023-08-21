/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

final class TestReactNativeView: UIView {
  @objc var reactTag = NSNumber(value: 5)
  var capturedAction: Selector?
  var stubbedWindow: UIWindow?

  override var window: UIWindow? {
    stubbedWindow
  }
}
