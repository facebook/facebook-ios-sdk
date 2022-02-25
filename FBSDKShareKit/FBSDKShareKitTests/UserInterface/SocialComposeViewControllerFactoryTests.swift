/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import XCTest

final class SocialComposeViewControllerFactoryTests: XCTestCase {

  var factory: SocialComposeViewControllerFactory! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    factory = SocialComposeViewControllerFactory()
  }

  func testMakingViewController() {
    let controller = factory.makeSocialComposeViewController()
    XCTAssertEqual(controller.serviceType, "com.apple.social.facebook", .controllerHasFacebookServiceType)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let controllerHasFacebookServiceType = "A controller with the Facebook service type should be made"
}
