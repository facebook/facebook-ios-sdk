/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

final class AuthenticationStatusUtilityTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  let url = URL(string: "m.facebook.com/platform/oidc/status/")! // swiftlint:disable:this force_unwrapping
  var sessionDataTask: TestSessionDataTask!
  var sessionDataTaskProvider: TestSessionProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    AuthenticationStatusUtility.resetClassDependencies()

    TestAccessTokenWallet.stubbedCurrentAccessToken = SampleAccessTokens.validToken
    TestAuthenticationTokenWallet.currentAuthenticationToken = SampleAuthenticationToken.validToken
    TestProfileProvider.current = SampleUserProfiles.createValid()

    sessionDataTask = TestSessionDataTask()
    sessionDataTaskProvider = TestSessionProvider()
    sessionDataTaskProvider.stubbedDataTask = sessionDataTask

    AuthenticationStatusUtility.configure(
      withProfileSetter: TestProfileProvider.self,
      sessionDataTaskProvider: sessionDataTaskProvider,
      accessTokenWallet: TestAccessTokenWallet.self,
      authenticationTokenWallet: TestAuthenticationTokenWallet.self
    )
  }

  override func tearDown() {
    AuthenticationStatusUtility.resetClassDependencies()
    TestAccessTokenWallet.reset()
    TestAuthenticationTokenWallet.reset()
    TestProfileProvider.reset()
    sessionDataTask = nil
    sessionDataTaskProvider = nil

    super.tearDown()
  }

  func testDefaultClassDependencies() {
    AuthenticationStatusUtility.resetClassDependencies()

    XCTAssertNil(
      AuthenticationStatusUtility.profileSetter,
      "Should not have a profile setter by default"
    )
    XCTAssertNil(
      AuthenticationStatusUtility.sessionDataTaskProvider,
      "Should not have a session data task provider by default"
    )
    XCTAssertNil(
      AuthenticationStatusUtility.accessTokenWallet,
      "Should not have an access token default"
    )
    XCTAssertNil(
      AuthenticationStatusUtility.authenticationTokenWallet,
      "Should not have an authentication token by default"
    )
  }

  func testConfiguringWithCustomClassDependencies() {
    XCTAssertTrue(
      AuthenticationStatusUtility.profileSetter === TestProfileProvider.self,
      "Should be able to set a custom profile setter"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.sessionDataTaskProvider === sessionDataTaskProvider,
      "Should be able to set a custom session data task provider"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.accessTokenWallet === TestAccessTokenWallet.self,
      "Should be able to set a custom access token"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.authenticationTokenWallet === TestAuthenticationTokenWallet.self,
      "Should be able to set a custom authentication token"
    )
  }

  func testCheckAuthenticationStatusWithNoToken() {
    TestAuthenticationTokenWallet.currentAuthenticationToken = nil
    AuthenticationStatusUtility.checkAuthenticationStatus()

    XCTAssertNil(
      sessionDataTaskProvider.capturedRequest,
      "Should not create a request if there is no authentication token"
    )

    XCTAssertNotNil(
      TestAccessTokenWallet.currentAccessToken,
      "Should not reset the current access token on failure to check the status of an authentication token"
    )
    XCTAssertNotNil(
      TestProfileProvider.current,
      "Should not reset the current profile on failure to check the status of an authentication token"
    )
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
      TestAuthenticationTokenWallet.currentAuthenticationToken,
      "Authentication token should be cleared when not authorized"
    )
    XCTAssertNil(
      TestAccessTokenWallet.currentAccessToken,
      "Access token should be cleared when not authorized"
    )
    XCTAssertNil(
      TestProfileProvider.current,
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
      TestAuthenticationTokenWallet.currentAuthenticationToken,
      "Authentication token should not be cleared when connected"
    )
    XCTAssertNotNil(
      TestAccessTokenWallet.currentAccessToken,
      "Access token should not be cleared when connected"
    )
    XCTAssertNotNil(
      TestProfileProvider.current,
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
      TestAuthenticationTokenWallet.currentAuthenticationToken,
      "Authentication token should not be cleared when connected"
    )
    XCTAssertNotNil(
      TestAccessTokenWallet.currentAccessToken,
      "Access token should not be cleared when connected"
    )
    XCTAssertNotNil(
      TestProfileProvider.current,
      "Profile should not be cleared when connected"
    )
  }

  func testHandleResponseWithFuzzyData() {
    for _ in 0 ..< 100 {
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
