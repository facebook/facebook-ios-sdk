/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices
import XCTest

class ChooseContextDialogFactoryTests: XCTestCase {

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
        content: content,
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
