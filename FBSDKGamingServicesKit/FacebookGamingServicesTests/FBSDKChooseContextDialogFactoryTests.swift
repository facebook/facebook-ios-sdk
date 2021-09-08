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

import FacebookGamingServices
import XCTest

class FBSDKChooseContextDialogFactoryTests: XCTestCase {

  var content: ChooseContextContent {
    let content = ChooseContextContent()
    content.filter = .newPlayersOnly
    content.maxParticipants = 100
    content.minParticipants = 1000

    return content
  }

  let delegate = TestContextDialogDelegate()

  func testCreatingDialog() throws {
    let dialog = try XCTUnwrap(
      ChooseContextDialogFactory().makeChooseContextDialog(
        with: content,
        delegate: delegate
      ) as? ChooseContextDialog,
      "Should create a context dialog of the expected concrete type"
    )

    XCTAssertEqual(
      dialog.dialogContent as? ChooseContextContent,
      content,
      "Should create the dialog with the expected content"
    )
    XCTAssertTrue(
      dialog.delegate === delegate,
      "Should create the dialog with the expected delegate"
    )
  }
}

// swiftlint:disable override_in_extension
extension ChooseContextContent {
  open override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? ChooseContextContent else {
      return false
    }

    return filter == other.filter &&
      maxParticipants == other.maxParticipants &&
      minParticipants == other.minParticipants
  }
}
