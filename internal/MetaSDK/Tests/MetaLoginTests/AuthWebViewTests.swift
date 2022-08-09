/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import AuthenticationServices
import XCTest

final class AuthWebViewTests: XCTestCase {
  var authWebView: AuthWebView!
  var webAuthSessionFactory: TestWebAuthenticationSessionFactory!
  var authSession: TestWebAuthenticationSession!
  var presentationContextProvider: TestWebAuthenticationSessionPresentationContextProvider!
  var localStorage: TestLocalStorage!
  let sampleURL = SampleURLs.example
  let sampleCallbackURLScheme = "metalogin"

  override func setUp() {
    super.setUp()

    authWebView = AuthWebView()
    presentationContextProvider = TestWebAuthenticationSessionPresentationContextProvider()
    localStorage = TestLocalStorage()
    authSession = TestWebAuthenticationSession(stubbedPresentationContextProvider: presentationContextProvider)
    webAuthSessionFactory = TestWebAuthenticationSessionFactory(stubbedSession: authSession)
    authWebView.setDependencies(
      .init(
        webAuthenticationSessionFactory: webAuthSessionFactory,
        presentationContextProvider: presentationContextProvider,
        localStorage: localStorage
      )
    )
  }

  override func tearDown() {
    authWebView = nil
    authSession = nil
    webAuthSessionFactory = nil
    presentationContextProvider = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    authWebView.resetDependencies()
    let dependencies = try authWebView.getDependencies()

    XCTAssertTrue(
      dependencies.webAuthenticationSessionFactory is WebAuthenticationSessionFactory,
      "A web authentication view uses a provided web authentication session factory"
    )
    XCTAssertTrue(
      dependencies.presentationContextProvider is WebAuthenticationSessionPresentationContextProvider,
      "A web authentication view uses a provided presentation context provider"
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try authWebView.getDependencies()

    XCTAssertTrue(
      dependencies.webAuthenticationSessionFactory is TestWebAuthenticationSessionFactory,
      "Should be set to custom web authentication session factory"
    )
    XCTAssertTrue(
      dependencies.presentationContextProvider is TestWebAuthenticationSessionPresentationContextProvider,
      "Should be set to custom presentation context provider"
    )
  }

  func testOpenURLWithSessionSuccess() throws {
    var capturedResult: Result<URL, Error>?
    authWebView.openURL(
      url: sampleURL,
      callbackURLScheme: sampleCallbackURLScheme
    ) { result in
      capturedResult = result
    }

    XCTAssertEqual(
      webAuthSessionFactory.capturedURL,
      sampleURL,
      "Should pass sample url to the authentication session"
    )
    XCTAssertEqual(
      webAuthSessionFactory.capturedCallbackURLScheme,
      sampleCallbackURLScheme,
      "Should pass sample callback url scheme to the authentication session"
    )

    let url = SampleURLs.loginRedirect(path: "#foo")
    webAuthSessionFactory.capturedCompletionHandler?(.success(url))
    XCTAssertNotNil(capturedResult, "Should capture result at completion")
    XCTAssertEqual(try capturedResult?.get(), url, "Should invoke the completion handler with the expected result")

    XCTAssertIdentical(
      authSession.presentationContextProvider,
      presentationContextProvider,
      "Should pass the presentation context provider to the authentication session"
    )
    XCTAssertTrue(authSession.startWasCalled, "Authentication session starts when openURL is called")
    XCTAssertEqual(
      localStorage.authenticationSessionState,
      .performingLogin,
      "Session state should be set to .performinglogin after successfully starting authentication session"
    )
  }

  func testOpenURLWithCanceledSession() throws {
    var capturedResult: Result<URL, Error>?
    var capturedError: Error?
    authWebView.openURL(
      url: sampleURL,
      callbackURLScheme: sampleCallbackURLScheme
    ) { result in
      capturedResult = result
      if case let .failure(error) = result {
        capturedError = error
      }
    }

    let error = ASWebAuthenticationSessionError(.canceledLogin, userInfo: [:])
    webAuthSessionFactory.capturedCompletionHandler?(.failure(error))
    XCTAssertNotNil(capturedResult, "Should capture result at completion")

    let unwrappedError = try XCTUnwrap(capturedError, "Should capture error at completion")
    XCTAssertIdentical(
      unwrappedError as AnyObject,
      error as AnyObject,
      "Authentication session error should be set to assigned value"
    )
    XCTAssertEqual(
      localStorage.authenticationSessionState,
      .canceled,
      "Session state should be set to .canceled when the canceled login error is returned"
    )
  }

  func testOpenURLWithPresentationContextNotProvided() throws {
    var capturedResult: Result<URL, Error>?
    var capturedError: Error?
    authWebView.openURL(
      url: sampleURL,
      callbackURLScheme: sampleCallbackURLScheme
    ) { result in
      capturedResult = result
      if case let .failure(error) = result {
        capturedError = error
      }
    }

    let error = ASWebAuthenticationSessionError(.presentationContextNotProvided, userInfo: [:])
    webAuthSessionFactory.capturedCompletionHandler?(.failure(error))
    XCTAssertNotNil(capturedResult, "Should capture result at completion")

    let unwrappedError = try XCTUnwrap(capturedError, "Should capture error at completion")
    XCTAssertIdentical(
      unwrappedError as AnyObject,
      error as AnyObject,
      "Authentication session error should be set to assigned value"
    )
    XCTAssertEqual(
      localStorage.authenticationSessionState,
      .canceled,
      "Session state should be set to .canceled when the presentation context is not provided"
    )
  }

  func testOpenURLWithPresentationContextInvalid() throws {
    var capturedResult: Result<URL, Error>?
    var capturedError: Error?
    authWebView.openURL(
      url: sampleURL,
      callbackURLScheme: sampleCallbackURLScheme
    ) { result in
      capturedResult = result
      if case let .failure(error) = result {
        capturedError = error
      }
    }

    let error = ASWebAuthenticationSessionError(.presentationContextInvalid, userInfo: [:])
    webAuthSessionFactory.capturedCompletionHandler?(.failure(error))
    XCTAssertNotNil(capturedResult, "Should capture result at completion")

    let unwrappedError = try XCTUnwrap(capturedError, "Should capture error at completion")
    XCTAssertIdentical(
      unwrappedError as AnyObject,
      error as AnyObject,
      "Authentication session error should be set to assigned value"
    )
    XCTAssertEqual(
      localStorage.authenticationSessionState,
      .canceled,
      "Session state should be set to .canceled when there is an invalid presentation context"
    )
  }
}
