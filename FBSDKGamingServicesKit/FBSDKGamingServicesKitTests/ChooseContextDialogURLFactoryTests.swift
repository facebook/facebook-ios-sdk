/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import XCTest

final class ChooseContextDialogURLFactoryTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var chooseContent: ChooseContextContent!
  let appID = "12345"

  override func setUp() {
    super.setUp()

    chooseContent = ChooseContextContent()
  }

  override func tearDown() {
    chooseContent = nil

    super.tearDown()
  }

  func testContextChooseDialogURL() throws {
    let URLFactory = ChooseContextDialogURLFactory(appID: appID, content: chooseContent)
    let chooseDialogURL = try URLFactory.generateDialogDeeplinkURL()
    let chooseDialogURLComponents = try XCTUnwrap(
      URLComponents(
        url: chooseDialogURL,
        resolvingAgainstBaseURL: false
      )
    )
    var queryParameters = [String: String]()
    chooseDialogURLComponents.queryItems?.forEach { queryParameters[$0.name] = $0.value }

    XCTAssertEqual(
      chooseDialogURLComponents.host,
      "fb.gg",
      "The host for the created url should be fb.gg"
    )
    XCTAssertEqual(
      chooseDialogURLComponents.path,
      "/dialog/choosecontext/\(appID)",
      "The path for the created url should be /me/instant_tournament/{app_id}"
    )
    XCTAssertEqual(queryParameters["filter"], "NO_FILTER")
    XCTAssertEqual(queryParameters["min_size"], "0")
    XCTAssertEqual(queryParameters["max_size"], "0")
  }
}
