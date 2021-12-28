/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import XCTest

class ChooseContextDialogTests: XCTestCase, ContextDialogDelegate {

  var dialogDidCompleteSuccessfully = false
  var dialogDidCancel = false
  var dialogError: NSError?
  let defaultAppID = "abc123"
  let msiteParamsQueryString = #"{"filter": "NO_FILTER", "min_size": 0, "max_size": 0, "app_id": "abc123"}"#

  override func setUp() {
    super.setUp()

    dialogDidCompleteSuccessfully = false
    dialogDidCancel = false
    dialogError = nil
    ApplicationDelegate.shared.application(
      UIApplication.shared,
      didFinishLaunchingWithOptions: [:]
    )
    Settings.shared.appID = defaultAppID
  }

  override func tearDown() {
    super.tearDown()

    GamingContext.current = nil
  }

  func testDialogCompletingWithValidContextID() throws {
    let validCallbackURL = URL(string: "fbabc123://gaming/contextchoose/?context_id=123456789&context_size=3")

    let dialog = try XCTUnwrap(SampleContextDialogs.chooseContextDialogWithoutContentValues(delegate: self))
    dialog.show()
    let dialogURLOpenerDelegate = try XCTUnwrap(dialog as? URLOpening)
    dialogURLOpenerDelegate
      .application(UIApplication.shared, open: validCallbackURL, sourceApplication: "", annotation: nil)

    XCTAssertNotNil(dialog)
    XCTAssertTrue(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    // TODO: Fix tests to have completion handler begin called
    if let nsError = dialogError?.userInfo[NSUnderlyingErrorKey] as? NSError,
       let errorMessage = nsError.userInfo[ErrorLocalizedDescriptionKey] as? String,
       errorMessage != "Cannot login due to urlOpener being nil" {
      XCTAssertNil(dialogError)
    }

    XCTAssertEqual(GamingContext.current?.size, 3)
    XCTAssertEqual(GamingContext.current?.identifier, "123456789")
  }

  func testCompletingWithEmptyContextID() throws {
    GamingContext.current = GamingContext(identifier: name, size: 2)

    let url = URL(string: "fbabc123://gaming/contextchoose/?context_id=")

    let dialog = try XCTUnwrap(SampleContextDialogs.chooseContextDialogWithoutContentValues(delegate: self))
    dialog.show()
    let dialogURLOpenerDelegate = try XCTUnwrap(dialog as? URLOpening)
    dialogURLOpenerDelegate
      .application(UIApplication.shared, open: url, sourceApplication: "", annotation: nil)

    XCTAssertTrue(
      dialogDidCancel,
      "Should cancel if a context cannot be created from the URL"
    )
    XCTAssertNil(
      GamingContext.current,
      "Should clear the current context when completing with an invalid url"
    )
  }

  func testDialogCancels() throws {
    let dialog = try XCTUnwrap(SampleContextDialogs.chooseContextDialogWithoutContentValues(delegate: self))
    dialog.show()
    let dialogURLOpenerDelegate = try XCTUnwrap(dialog as? URLOpening)
    dialogURLOpenerDelegate.applicationDidBecomeActive(UIApplication.shared)

    XCTAssertNotNil(dialog)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertTrue(dialogDidCancel)
    // TODO: Fix tests to have completion handler begin called
    if let nsError = dialogError?.userInfo[NSUnderlyingErrorKey] as? NSError,
       let errorMessage = nsError.userInfo[ErrorLocalizedDescriptionKey] as? String,
       errorMessage != "Cannot login due to urlOpener being nil" {
      XCTAssertNil(dialogError)
    }
  }

  func testShowDialogThroughAppSwitch() throws {
    let util = TestInternalUtility()
    util.isFacebookAppInstalled = true
    let dialog = try XCTUnwrap(SampleContextDialogs.chooseContextDialog(utility: util, delegate: self))

    dialog.show()
    let filterQuery = try XCTUnwrap(util.queryParameters?[URLConstants.queryParameterFilter])
    let maxSizeQuery = try XCTUnwrap(util.queryParameters?[URLConstants.queryParameterMaxSize])
    let minSizeQuery = try XCTUnwrap(util.queryParameters?[URLConstants.queryParameterMinSize])

    XCTAssertNotNil(dialog)
    XCTAssertEqual(util.scheme, URLScheme.https.rawValue)
    XCTAssertEqual(util.host, URLConstants.host)
    XCTAssertEqual(util.path, URLConstants.appSwitch(appID: defaultAppID).path)
    XCTAssertEqual(filterQuery, "NO_FILTER")
    XCTAssertEqual(maxSizeQuery, "0")
    XCTAssertEqual(minSizeQuery, "0")
  }

  func testShowDialogWithoutSettingAppID() throws {
    let appIDErrorMessage = "App ID is not set in settings"
    let content = ChooseContextContent()
    let dialog = ChooseContextDialog(content: content, delegate: self)
    Settings.shared.appID = nil
    dialog.show()

    let dialogError = try XCTUnwrap(dialogError)
    XCTAssertNotNil(dialog)
    XCTAssertEqual(CoreError.errorUnknown.rawValue, dialogError.code)
    XCTAssertEqual(appIDErrorMessage, dialogError.userInfo[ErrorDeveloperMessageKey] as? String)
  }

  func testShowDialogWithInvalidSizeContent() throws {
    let appIDErrorMessage = "The minimum size cannot be greater than the maximum size"
    let contentErrorName = "minParticipants"
    let dialog = try XCTUnwrap(SampleContextDialogs.showChooseContextDialogWithInvalidSizes(delegate: self))
    dialog.show()

    let dialogError = try XCTUnwrap(dialogError)
    XCTAssertNotNil(dialog)
    XCTAssertNotNil(dialogError)
    XCTAssertEqual(CoreError.errorInvalidArgument.rawValue, dialogError.code)
    XCTAssertEqual(appIDErrorMessage, dialogError.userInfo[ErrorDeveloperMessageKey] as? String)
    XCTAssertEqual(contentErrorName, dialogError.userInfo[ErrorArgumentNameKey] as? String)
  }

  func testShowDialogWithNullValuesInContent() throws {
    let dialog = try XCTUnwrap(SampleContextDialogs.chooseContextDialogWithoutContentValues(delegate: self))
    dialog.show()

    XCTAssertNotNil(dialog)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    // TODO: Fix tests to have completion handler begin called
    if let nsError = dialogError?.userInfo[NSUnderlyingErrorKey] as? NSError,
       let errorMessage = nsError.userInfo[ErrorLocalizedDescriptionKey] as? String,
       errorMessage != "Cannot login due to urlOpener being nil" {
      XCTAssertNil(dialogError)
    }
  }

  // MARK: - Delegate Methods

  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {
    dialogDidCompleteSuccessfully = true
  }

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {
    dialogError = error as NSError
  }

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {
    dialogDidCancel = true
  }
}
