/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import FBSDKGamingServicesKit

import TestTools
import XCTest

final class JoinTournamentDialogTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var joinDialog: JoinTournamentDialog!
  var dialogCompleted = false
  var dialogFailed = false
  var error: Error?
  var tournamentID: String?
  var payload: String?
  let tournamentKey = "tournament_id"
  let payloadKey = "payload"
  let expectedPayload = "test payload"
  let expectedTournamentID = "test tournament"

  override func setUp() {
    super.setUp()

    dialogCompleted = false
    dialogFailed = false
    error = nil
    tournamentID = nil
    payload = nil
    joinDialog = JoinTournamentDialog()
    joinDialog.dialog = _WebDialog(name: "Test")

    _WebDialog.setDependencies(
      .init(
        errorFactory: TestErrorFactory(),
        windowFinder: TestWindowFinder(window: UIWindow())
      )
    )
  }

  override func tearDown() {
    super.tearDown()

    _WebDialog.resetDependencies()
  }

  func testDialogSucceeds() throws {
    showSpecific()
    let result = [
      tournamentKey: expectedTournamentID,
      payloadKey: expectedPayload,
    ]
    joinDialog.dialog?.complete(with: result)
    XCTAssertNil(error)
    XCTAssertFalse(dialogFailed)
    XCTAssertTrue(dialogCompleted)
    XCTAssertEqual(payload, expectedPayload)
    XCTAssertEqual(tournamentID, expectedTournamentID)
  }

  func testDialogFailsWithoutTournamentID() throws {
    showSpecific()
    joinDialog.dialog?.complete(with: [:])

    XCTAssertFalse(dialogCompleted)
    XCTAssertTrue(dialogFailed)
    XCTAssertNotNil(error)
    XCTAssertNil(payload)
    XCTAssertNil(tournamentID)
  }

  func testDialogFailsWithError() throws {
    showSpecific()
    let error = NSError(domain: "I'm a teapot", code: 418)
    joinDialog.dialog?.fail(with: error)

    XCTAssertTrue(dialogFailed)
    XCTAssertFalse(dialogCompleted)
    XCTAssertNotNil(error)
    XCTAssertNil(payload)
    XCTAssertNil(tournamentID)
  }

  func testSuggestedSucceeds() throws {
    showSuggested()
    let result = [
      tournamentKey: expectedTournamentID,
      payloadKey: expectedPayload,
    ]
    joinDialog.dialog?.complete(with: result)
    XCTAssertNil(error)
    XCTAssertFalse(dialogFailed)
    XCTAssertTrue(dialogCompleted)
    XCTAssertEqual(payload, expectedPayload)
    XCTAssertEqual(tournamentID, expectedTournamentID)
  }

  func showSpecific() {
    joinDialog.showSpecific(tournamentID: expectedTournamentID, payload: expectedPayload) { result in
      switch result {
      case let .success(success):
        self.tournamentID = success.tournamentID
        self.payload = success.payload
        self.dialogCompleted = true
      case let .failure(error):
        self.error = error
        self.dialogFailed = true
      }
    }
  }

  func showSuggested() {
    joinDialog.showSuggested(payload: expectedPayload) { result in
      switch result {
      case let .success(success):
        self.tournamentID = success.tournamentID
        self.payload = success.payload
        self.dialogCompleted = true
      case let .failure(error):
        self.error = error
        self.dialogFailed = true
      }
    }
  }
}
