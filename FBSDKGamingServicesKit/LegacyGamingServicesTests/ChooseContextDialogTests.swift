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

import XCTest

class ChooseContextDialogTests: XCTestCase, ContextDialogDelegate {

  var dialogDidCompleteSuccessfully = false
  var dialogDidCancel = false
  var dialogError: NSError?
  let defaultAppID = "abc123"
  let msiteParamsQueryString = "{\"filter\":\"NEW_CONTEXT_ONLY\",\"min_size\":0,\"max_size\":0,\"app_id\":\"abc123\"}"

  override func setUp() {
    super.setUp()

    dialogDidCompleteSuccessfully = false
    dialogDidCancel = false
    dialogError = nil
    ApplicationDelegate.shared.application(
      UIApplication.shared,
      didFinishLaunchingWithOptions: [:]
    )
    Settings.appID = defaultAppID
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
    XCTAssertNil(dialogError)
    XCTAssertEqual(GamingContext.current?.size, 3)
    XCTAssertEqual(GamingContext.current?.identifier, "123456789")
  }

  func testCompletingWithEmptyContextID() throws {
    GamingContext.current = GamingContext.createContext(withIdentifier: name, size: 2)

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
    XCTAssertNil(dialogError)
  }

  func testShowDialogThroughAppSwitch() throws {
    let util = TestInternalUtility(isFacebookAppInstalled: true)
    let dialog = try XCTUnwrap(SampleContextDialogs.chooseContextDialog(utility: util, delegate: self))

    dialog.show()
    let filterQuery = try XCTUnwrap(util.queryParameters?[URLConstants.queryParameterFilter] as? String)
    let maxSizeQuery  = try XCTUnwrap(util.queryParameters?[URLConstants.queryParameterMaxSize] as? Int)
    let minSizeQuery  = try XCTUnwrap(util.queryParameters?[URLConstants.queryParameterMinSize] as? Int)

    XCTAssertNotNil(dialog)
    XCTAssertEqual(util.scheme, URLConstants.scheme)
    XCTAssertEqual(util.host, URLConstants.host)
    XCTAssertEqual(util.path, URLConstants.appSwitch(appID: defaultAppID).path)
    XCTAssertEqual(filterQuery, "NEW_CONTEXT_ONLY")
    XCTAssertEqual(maxSizeQuery, 0)
    XCTAssertEqual(minSizeQuery, 0)
  }

  func testShowDialogThroughMSite() throws {
    let util = TestInternalUtility(isFacebookAppInstalled: false)
    let dialog = try XCTUnwrap(SampleContextDialogs.chooseContextDialog(utility: util, delegate: self))

    dialog.show()
    let pathQuery = try XCTUnwrap(util.queryParameters?[URLConstants.mSiteQueryParameterPath] as? String)
    let paramsQuery = try XCTUnwrap(util.queryParameters?[URLConstants.mSiteQueryParameterParams] as? String)

    XCTAssertNotNil(dialog)
    XCTAssertEqual(util.scheme, URLConstants.scheme)
    XCTAssertEqual(util.host, URLConstants.host)
    XCTAssertEqual(util.path, URLConstants.mSite.path)
    XCTAssertEqual(pathQuery, "/path")
    XCTAssertEqual(paramsQuery, msiteParamsQueryString)
  }

  func testShowDialogWithoutSettingAppID() throws {
    let appIDErrorMessage = "App ID is not set in settings"
    let content = ChooseContextContent()
    let dialog = ChooseContextDialog(content: content, delegate: self)
    Settings.appID = nil
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
    XCTAssertNil(dialogError)
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
