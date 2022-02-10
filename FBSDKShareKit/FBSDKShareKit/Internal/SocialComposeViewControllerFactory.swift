/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Social

final class SocialComposeViewControllerFactory: _SocialComposeViewControllerFactoryProtocol {
  var canMakeSocialComposeViewController: Bool {
    SLComposeViewController.isAvailable(
      forServiceType: _FBSDKSocialComposeServiceType
    )
  }

  func makeSocialComposeViewController() -> _SocialComposeViewControllerProtocol? {
    if canMakeSocialComposeViewController {
      return SLComposeViewController(
        forServiceType: _FBSDKSocialComposeServiceType
      ) as? _SocialComposeViewControllerProtocol
    } else {
      return nil
    }
  }
}
#endif
