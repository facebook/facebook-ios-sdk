// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import TestTools
import XCTest

class FBSDKSwitchContextDialogFactoryTests: XCTestCase {

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
        with: content,
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
        with: content,
        windowFinder: windowFinder,
        delegate: delegate
      ),
      "Should not create a dialog with a missing access token"
    )
  }
}
