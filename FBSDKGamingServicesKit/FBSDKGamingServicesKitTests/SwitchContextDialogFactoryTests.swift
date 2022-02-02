/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import TestTools
import XCTest

final class SwitchContextDialogFactoryTests: XCTestCase {

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
    var capturedError: ContextDialogPresenterError?
    var switchDialog: SwitchContextDialog?

    do {
      switchDialog = try factory.makeSwitchContextDialog(
        content: content,
        windowFinder: windowFinder,
        delegate: delegate
      ) as? SwitchContextDialog
    } catch {
      capturedError = error as? ContextDialogPresenterError
    }
    XCTAssertEqual(
      capturedError,
      ContextDialogPresenterError.invalidAccessToken,
      "Should throw ContextDialogPresenterError.invalidAccessToken error"
    )
    XCTAssertNil(
      switchDialog,
      "Should not create a context dialog with a missing access token"
    )
  }
}
