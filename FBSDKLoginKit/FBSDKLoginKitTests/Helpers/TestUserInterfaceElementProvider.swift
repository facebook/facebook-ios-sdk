/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class TestUserInterfaceElementProvider: UserInterfaceElementProviding {
  var stubbedTopMostViewController: UIViewController?
  var capturedView: UIView?

  func topMostViewController() -> UIViewController? {
    stubbedTopMostViewController
  }

  func viewController(for view: UIView) -> UIViewController? {
    capturedView = view
    return stubbedTopMostViewController
  }
}
