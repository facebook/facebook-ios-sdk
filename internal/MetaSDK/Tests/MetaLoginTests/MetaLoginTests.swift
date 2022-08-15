/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class MetaLoginTests: XCTestCase {
  var authWebView: TestAuthWebView!
  var metaLogin: MetaLogin!
  var localStorage: TestLocalStorage!

  override func setUp() {
    super.setUp()

    localStorage = TestLocalStorage()
    metaLogin = MetaLogin()
    authWebView = TestAuthWebView()
    metaLogin.setDependencies(
      .init(
        urlOpener: authWebView,
        localStorage: localStorage
      )
    )
  }

  override func tearDown() {
    metaLogin = nil
    authWebView = nil
    localStorage = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    metaLogin.resetDependencies()
    let dependencies = try metaLogin.getDependencies()

    XCTAssertTrue(
      dependencies.urlOpener is AuthWebView,
      "A login manager uses a provided authentication web view"
    )
    XCTAssertTrue(
      dependencies.localStorage is LocalStorage,
      "A login manager uses a provided LocalStorage"
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try metaLogin.getDependencies()

    XCTAssertTrue(
      dependencies.urlOpener is TestAuthWebView,
      "Should be set to a custom authentication web view"
    )
    XCTAssertTrue(
      dependencies.localStorage is TestLocalStorage,
      "A login manager uses a custom LocalStorage"
    )
  }

  func testLogin() throws {
    var wasCalled = false
    let loginConfiguration = try XCTUnwrap(
      LoginConfiguration(
        permissions: [.publicProfile],
        facebookAppID: "facebook_app_id",
        metaAppID: "some_meta_app_id"
      )
    )

    metaLogin.logIn(configuration: loginConfiguration) { result in
      switch result {
      case let .success(result):
        XCTAssertNotNil(result, "Should receive a success result from login")
      case .failure:
        XCTFail("Should not receive a failure result for login")
      }
      wasCalled = true
    }

    authWebView.capturedCompletion?(.success(SampleURLs.loginRedirect))
    XCTAssertTrue(wasCalled, "Completion handler should be called synchronously")
  }

  func testLogout() throws {
    localStorage.authenticationSessionState = .performingLogin
    metaLogin.logOut()
    XCTAssertEqual(
      localStorage.authenticationSessionState,
      .none,
      "AuthenticationSessionState should be set as none after user logs out"
    )
    XCTAssertTrue(
      localStorage.isDeleteUserSessionCalled,
      "Should delete the stored user session when a user logs out"
    )
  }

  func testLoginWithInvalidIncomingAuthenticationURL() throws {
    let loginConfiguration = try XCTUnwrap(
      LoginConfiguration(
        permissions: [.publicProfile],
        facebookAppID: "facebook_app_id",
        metaAppID: "some_meta_app_id"
      )
    )
    var capturedError: Error?

    metaLogin.logIn(configuration: loginConfiguration) { result in
      if case let .failure(error) = result {
        capturedError = error
      }
    }

    let url = SampleURLs.example(path: "foo")
    authWebView.capturedCompletion?(.success(url))
    XCTAssertNotNil(
      capturedError,
      "Should return URL error if the incoming URL does not begin with the Meta Login redirect uri"
    )
  }

  func testIsValidAuthenticationURLWithValidURL() throws {
    let sampleURL = SampleURLs.LoginResponses.withDefaultParameters
    let isValid = metaLogin.isValidAuthenticationURL(url: sampleURL)

    XCTAssertTrue(isValid, "Should return true when URL begins with the Meta login redirect uri")
  }

  func testIsValidAuthenticationURLWithValidHostAndInvalidScheme() throws {
    let sampleURL = URL(string: "fbconnect://failure")!
    let isValid = metaLogin.isValidAuthenticationURL(url: sampleURL)

    XCTAssertFalse(isValid, "Should return false when URL does not begin with the Meta login redirect uri")
  }

  func testIsValidAuthenticationURLWithInvalidURLAndValidScheme() throws {
    let sampleURL = URL(string: "example://success")!
    let isValid = metaLogin.isValidAuthenticationURL(url: sampleURL)

    XCTAssertFalse(isValid, "Should return false when URL does not begin with the Meta login redirect uri")
  }

  func testIsValidAuthenticationURLWithInvalidHostAndInvalidScheme() throws {
    let isValid = metaLogin.isValidAuthenticationURL(url: SampleURLs.example)

    XCTAssertFalse(isValid, "Should return false when URL does not begin with the Meta login redirect uri")
  }

  func testGetUserSession() throws {
    XCTAssertEqual(
      localStorage.stubbedUserSession,
      metaLogin.userSession,
      "The userSession variable should be consistent with cached data"
    )
  }

  func testGetUserSessionWithItemNotFoundError() throws {
    localStorage.stubbedError = LocalStorageError.itemNotFound
    XCTAssertNil(
      metaLogin.userSession,
      "The userSession should be nil when error occurs in localStorage get method "
    )
  }

  func testGetUserSessionWithUnhandledError() throws {
    localStorage.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    XCTAssertNil(
      metaLogin.userSession,
      "The userSession should be nil when error occurs in localStorage get method "
    )
  }
}
