/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices
import TestTools
import XCTest

class SwitchContextDialogFactoryTests: XCTestCase {

  let content = SwitchContextContent(contextID: "123")
  let windowFinder = TestWindowFinder()
  let delegate = TestContextDialogDelegate()
  let tokenProvider = TestAccessTokenProvider()

  override func setUp() {
    super.setUp()

    TestAccessTokenProvider.reset()
  }

  override func tearDown() {
    TestAccessTokenProvider.reset()

    super.tearDown()
  }

  func testCreatingDialogWithAccessToken() throws {
    TestAccessTokenProvider.stubbedAccessToken = SampleAccessTokens.validToken
    let factory = SwitchContextDialogFactory(tokenProvider: TestAccessTokenProvider.self)

    let dialog = try XCTUnwrap(
      factory.makeSwitchContextDialog(
        content: content,
        windowFinder: windowFinder,
        delegate: delegate
      ) as? SwitchContextDialog,
      "Should create a context dialog of the expected concrete type"
    )

    XCTAssertEqual(
      dialog.dialogContent as? SwitchContextContent,
      content,
      "Should create the dialog with the expected content"
    )
    XCTAssertTrue(
      dialog.delegate === delegate,
      "Should create the dialog with the expected delegate"
    )
  }

  func testCreatingDialogWithMissingAccessToken() throws {
    let factory = SwitchContextDialogFactory(tokenProvider: TestAccessTokenProvider.self)
    XCTAssertNil(
      factory.makeSwitchContextDialog(
        content: content,
        windowFinder: windowFinder,
        delegate: delegate
      ),
      "Should not create a dialog with a missing access token"
    )
  }
}
