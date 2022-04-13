/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class TooltipViewTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var tooltipView: FBTooltipView!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    tooltipView = FBTooltipView()
  }

  override func tearDown() {
    tooltipView = nil
    super.tearDown()
  }

  func testTooltipCreation() {
    let tagline = "foo"
    let message = "bar"
    tooltipView = FBTooltipView(tagline: tagline, message: message, colorStyle: .friendlyBlue)

    XCTAssertEqual(tooltipView.message, message, .createsWithParameters)
    XCTAssertEqual(tooltipView.tagline, tagline, .createsWithParameters)
    XCTAssertEqual(tooltipView.colorStyle, .friendlyBlue, .createsWithParameters)
  }

  // MARK: - Tooltip presentation

  func testPresentFromView() {
    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    tooltipView.present(from: rootVC.view)

    if !rootVC.view.subviews.contains(where: { $0 is FBTooltipView }) {
      XCTFail(.showsTooltip)
    }
  }

  func testPresentInViewWithArrowPositionDirection() {
    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    tooltipView.present(in: rootVC.view, arrowPosition: .zero, direction: .down)

    if !rootVC.view.subviews.contains(where: { $0 is FBTooltipView }) {
      XCTFail(.showsTooltip)
    }
  }

  func testAnimateFadeIn() {
    tooltipView.isHidden = true
    tooltipView.animateFadeIn()
    XCTAssertFalse(tooltipView.isHidden, .showsTooltip)
  }

  // MARK: - Tooltip Style

  func testSetMessage() throws {
    let tagline = "myTagline"
    let oldMessage = "myOldMessage"

    tooltipView = FBTooltipView(tagline: tagline, message: oldMessage, colorStyle: .friendlyBlue)

    XCTAssertEqual(tooltipView.message, oldMessage, .createsWithParameters)
    XCTAssertEqual(tooltipView.tagline, tagline, .createsWithParameters)

    let newMessage = "myNewMessage"
    tooltipView.message = newMessage

    XCTAssertEqual(tooltipView.textLabel.text, "\(tagline) \(newMessage)", .canChangeMessage)
  }

  func testSetTagline() throws {
    let oldTagline = "myOldTagline"
    let message = "myMessage"

    tooltipView = FBTooltipView(tagline: oldTagline, message: message, colorStyle: .friendlyBlue)

    XCTAssertEqual(tooltipView.message, message, .createsWithParameters)
    XCTAssertEqual(tooltipView.tagline, oldTagline, .createsWithParameters)

    let newTagline = "myNewTagline"
    tooltipView.tagline = newTagline

    XCTAssertEqual(tooltipView.textLabel.text, "\(newTagline) \(message)", .canChangeTagline)
  }

  func testSetColorStyle() throws {
    let tagline = "foo"
    let message = "bar"
    tooltipView = FBTooltipView(tagline: tagline, message: message, colorStyle: .friendlyBlue)
    tooltipView.colorStyle = .neutralGray
    XCTAssertEqual(tooltipView.colorStyle, .neutralGray, .canChangeColorStyle)

    XCTAssertEqual(tooltipView.textLabel.textColor, .white, .setsLabelColor)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let showsTooltip = "Can properly show the tooltip"
  static let createsWithParameters = "Creates a tooltip instance with the provided parameters"
  static let canChangeMessage = "Can properly change tooltip message with a new one"
  static let canChangeTagline = "Can properly change tooltip tagline with a new one"
  static let canChangeColorStyle = "Can properly change tooltip color style with a new one"
  static let setsLabelColor = "Sets tooltip text label color"
}
