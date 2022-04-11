/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class LoginTooltipViewTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var loginTooltipView: FBLoginTooltipView!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    loginTooltipView = FBLoginTooltipView()
  }

  override func tearDown() {
    loginTooltipView = nil
    super.tearDown()
  }

  func testPresentInViewWithArrowPositionDirectionWithForcedDisplay() {
    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    loginTooltipView.shouldForceDisplay = true
    loginTooltipView.present(in: rootVC.view, arrowPosition: .zero, direction: .down)

    if !rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.showsTooltip)
    }
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let showsTooltip = "Shows a tooltip when is forced to display"
}
