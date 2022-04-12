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
  var serverConfigurationProvider: TestServerConfigurationProvider!
  var stringProvider: TestUserInterfaceStringProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    serverConfigurationProvider = TestServerConfigurationProvider()
    stringProvider = TestUserInterfaceStringProvider()
    loginTooltipView = FBLoginTooltipView(
      serverConfigurationProvider: serverConfigurationProvider,
      stringProvider: stringProvider
    )
  }

  override func tearDown() {
    loginTooltipView = nil
    serverConfigurationProvider = nil
    stringProvider = nil
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

  func testPresentInViewWithArrowPositionDirectionEnabled() throws {
    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    loginTooltipView.present(in: rootVC.view, arrowPosition: .zero, direction: .down)

    let completion = try XCTUnwrap(serverConfigurationProvider.capturedCompletion, .showsTooltipIfEnabled)
    completion(FBSDKLoginTooltip(text: "foo", enabled: true), nil)

    if !rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.showsTooltipIfEnabled)
    }
  }

  func testPresentInViewWithArrowPositionDirectionDisabled() throws {
    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    loginTooltipView.present(in: rootVC.view, arrowPosition: .zero, direction: .down)

    let completion = try XCTUnwrap(serverConfigurationProvider.capturedCompletion, .doesNotShowTooltip)
    completion(FBSDKLoginTooltip(text: "foo", enabled: false), nil)

    if rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.doesNotShowTooltip)
    }
  }

  func testPresentInViewWithArrowPositionDirectionWithError() throws {
    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    loginTooltipView.present(in: rootVC.view, arrowPosition: .zero, direction: .down)

    let completion = try XCTUnwrap(serverConfigurationProvider.capturedCompletion, .doesNotShowTooltip)
    completion(FBSDKLoginTooltip(text: "foo", enabled: false), NSError(domain: "foo", code: -1))

    if rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.doesNotShowTooltip)
    }
  }

  func testPresentInViewWithArrowPositionDirectionWithNilResponse() throws {
    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    loginTooltipView.present(in: rootVC.view, arrowPosition: .zero, direction: .down)

    let completion = try XCTUnwrap(serverConfigurationProvider.capturedCompletion, .doesNotShowTooltip)
    completion(nil, nil)

    if rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.doesNotShowTooltip)
    }
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let showsTooltip = "Shows a tooltip when is forced to display"
  static let showsTooltipIfEnabled = "Shows a tooltip if enabled"
  static let doesNotShowTooltip = "Does not show a tooltip when disabled"
}
