/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

@objc(FBSDKUserInterfaceElementProviding)
public protocol UserInterfaceElementProviding {
  func topMostViewController() -> UIViewController?
  @objc(viewControllerForView:)
  func viewController(for view: UIView) -> UIViewController?
}
