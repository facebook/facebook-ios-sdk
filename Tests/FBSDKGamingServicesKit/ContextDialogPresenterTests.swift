/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKGamingServicesKit
import TestTools
import XCTest

class ContextDialogPresenterTests: XCTestCase, ContextDialogDelegate {

  override func setUp() {
    super.setUp()

    AccessToken.current = SampleAccessTokens.validToken
  }

  override func tearDown() {
    AccessToken.current = nil

    super.tearDown()
  }

  func testCreateContextDialog() {
    let content = CreateContextContent(playerID: "123")
    XCTAssertNotNil(
      FBSDKContextDialogPresenter.createContextDialog(
        withContent: content,
        delegate: self
      )
    )
  }

  func testShowCreateContextDialog() {
    let content = CreateContextContent(playerID: "123")
    XCTAssertNil(
      FBSDKContextDialogPresenter.showCreateContextDialog(
        withContent: content,
        delegate: self
      )
    )
  }

  func testSwitchContextDialog() {
    let content = SwitchContextContent(contextID: "123")
    XCTAssertNotNil(
      FBSDKContextDialogPresenter.switchContextDialog(
        withContent: content,
        delegate: self
      )
    )
  }

  func testShowSwitchContextDialog() {
    let content = SwitchContextContent(contextID: "123")
    XCTAssertNil(
      FBSDKContextDialogPresenter.showSwitchContextDialog(
        withContent: content,
        delegate: self
      )
    )
  }

  func testShowChooseContextDialog() {
    let content = ChooseContextContent()
    XCTAssertNotNil(
      FBSDKContextDialogPresenter.showChooseContextDialog(
        withContent: content,
        delegate: self
      )
    )
  }

  // MARK: - FBSDKContextDialogDelegate methods

  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {}

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {}

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {}
}
