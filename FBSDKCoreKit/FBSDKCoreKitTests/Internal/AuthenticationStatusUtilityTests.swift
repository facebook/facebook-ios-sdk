/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class AuthenticationStatusUtilityTests: XCTestCase {

  // swiftlint:disable:next force_unwrapping
  let url = URL(string: "m.facebook.com/platform/oidc/status/")!

  override func setUp() {
    super.setUp()

    AuthenticationToken.current = SampleAuthenticationToken.validToken
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)
    Profile.setCurrent(SampleUserProfiles.valid, shouldPostNotification: false)
  }

  func testCheckAuthenticationStatusWithNoToken() {
    AuthenticationToken.current = nil
    AuthenticationStatusUtility.checkAuthenticationStatus()

    XCTAssertNotNil(AccessToken.current)
    XCTAssertNotNil(Profile.current)
  }

  func testRequestURL() {
    let url = AuthenticationStatusUtility._requestURL()

    XCTAssertEqual(url.host, "m.facebook.com")
    XCTAssertEqual(url.path, "/platform/oidc/status")

    let params = InternalUtility.shared.parameters(fromFBURL: url)
    XCTAssertNotNil(
      params["id_token"],
      "Incorrect ID token parameter in request url"
    )
  }

  func testHandleNotAuthorizedResponse() {
    let header = ["fb-s": "not_authorized"]
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: header
    )! // swiftlint:disable:this force_unwrapping

    AuthenticationStatusUtility._handle(response)

    XCTAssertNil(
      AuthenticationToken.current,
      "Authentication token should be cleared when not authorized"
    )
    XCTAssertNil(
      AccessToken.current,
      "Access token should be cleared when not authorized"
    )
    XCTAssertNil(
      Profile.current,
      "Profile should be cleared when not authorized"
    )
  }

  func testHandleConnectedResponse() {
    let header = ["fb-s": "connected"]
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: header
    )! // swiftlint:disable:this force_unwrapping

    AuthenticationStatusUtility._handle(response)

    XCTAssertNotNil(
      AuthenticationToken.current,
      "Authentication token should not be cleared when connected"
    )
    XCTAssertNotNil(
      AccessToken.current,
      "Access token should not be cleared when connected"
    )
    XCTAssertNotNil(
      Profile.current,
      "Profile should not be cleared when connected"
    )
  }

  func testHandleNoStatusResponse() {
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [:]
    )! // swiftlint:disable:this force_unwrapping

    AuthenticationStatusUtility._handle(response)

    XCTAssertNotNil(
      AuthenticationToken.current,
      "Authentication token should not be cleared when connected"
    )
    XCTAssertNotNil(
      AccessToken.current,
      "Access token should not be cleared when connected"
    )
    XCTAssertNotNil(
      Profile.current,
      "Profile should not be cleared when connected"
    )
  }

  func testHandleResponseWithFuzzyData() {
    for _ in 0..<100 {
      let header = [
        "fb-s": Fuzzer.random.description,
        "some_header_key": Fuzzer.random.description,
      ]

      let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: header as? [String: String]
      )! // swiftlint:disable:this force_unwrapping

      AuthenticationStatusUtility._handle(response)
    }
  }
}
