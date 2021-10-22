/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

@objcMembers
final class TestSocialComposeViewControllerFactory: NSObject, SocialComposeViewControllerFactoryProtocol {
  var canMakeSocialComposeViewController = false
  var stubbedSocialComposeViewController: (UIViewController & SocialComposeViewControllerProtocol)?

  func makeSocialComposeViewController() -> SocialComposeViewControllerProtocol? {
    stubbedSocialComposeViewController
  }
}

@objcMembers
final class TestSocialComposeViewController: UIViewController, SocialComposeViewControllerProtocol {
  var completionHandler: FBSDKSocialComposeViewControllerCompletionHandler = { _ in }
  var stubbedSetInitialText = false
  var capturedInitialText: String?

  func setInitialText(_ text: String) -> Bool {
    capturedInitialText = text
    return stubbedSetInitialText
  }

  func add(_ image: UIImage) -> Bool {
    false
  }

  func add(_ url: URL) -> Bool {
    false
  }
}
