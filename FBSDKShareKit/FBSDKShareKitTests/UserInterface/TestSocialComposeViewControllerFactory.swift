/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import Foundation
import Social
import UIKit

final class TestSocialComposeViewControllerFactory: SocialComposeViewControllerFactoryProtocol {
  var stubbedSocialComposeViewController: SLComposeViewController?

  func makeSocialComposeViewController() -> SLComposeViewController {
    guard let viewController = stubbedSocialComposeViewController else {
      fatalError("A stubbed view controller is required")
    }

    return viewController
  }
}

final class TestSocialComposeViewController: SLComposeViewController {
  var stubbedSetInitialText = false
  var capturedInitialText: String?

  override func setInitialText(_ text: String) -> Bool {
    capturedInitialText = text
    return stubbedSetInitialText
  }

  override func add(_ image: UIImage) -> Bool {
    false
  }

  override func add(_ url: URL) -> Bool {
    false
  }
}
