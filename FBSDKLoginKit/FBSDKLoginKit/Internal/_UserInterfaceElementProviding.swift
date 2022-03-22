/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(_FBSDKUserInterfaceElementProviding)
public protocol _UserInterfaceElementProviding {
  func topMostViewController() -> UIViewController?
  @objc(viewControllerForView:)
  func viewController(for view: UIView) -> UIViewController?
}
