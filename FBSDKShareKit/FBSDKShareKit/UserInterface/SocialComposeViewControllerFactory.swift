/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Social

final class SocialComposeViewControllerFactory: SocialComposeViewControllerFactoryProtocol {
  private static let socialComposeServiceType = "com.apple.social.facebook"

  var canMakeSocialComposeViewController: Bool {
    SLComposeViewController.isAvailable(forServiceType: Self.socialComposeServiceType)
  }

  func makeSocialComposeViewController() -> SLComposeViewController {
    SLComposeViewController(forServiceType: Self.socialComposeServiceType)
  }
}
