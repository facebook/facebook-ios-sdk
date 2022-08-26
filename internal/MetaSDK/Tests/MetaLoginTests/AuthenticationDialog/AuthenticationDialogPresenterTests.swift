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

fileprivate extension CompletionLoginResult {
  func getURL() -> URL? {
    if case let .success(url) = self {
      return url
    }
    return nil
  }

  func isCancellation() -> Bool {
    if case .cancel = self {
      return true
    }
    return false
  }
}

final class AuthenticationDialogPresenterTests: XCTestCase {
  var presenter: AuthenticationDialogPresenter!
  var webAuthSessionFactory: TestWebAuthenticationSessionFactory!
  var authSession: TestWebAuthenticationSession!
  var presentationContextProvider: TestWebAuthenticationSessionPresentationContextProvider!
  var authenticationSessionStateStore: TestAuthenticationSessionStateStore!
  let sampleURL = SampleURLs.example
  let sampleCallbackURLScheme = "metalogin"

  override func setUp() {
    super.setUp()

    presenter = AuthenticationDialogPresenter()
    presentationContextProvider = TestWebAuthenticationSessionPresentationContextProvider()
    authenticationSessionStateStore = TestAuthenticationSessionStateStore()
    authSession = TestWebAuthenticationSession(stubbedPresentationContextProvider: presentationContextProvider)
    webAuthSessionFactory = TestWebAuthenticationSessionFactory(stubbedSession: authSession)
    presenter.setDependencies(
      .init(
        webAuthenticationSessionFactory: webAuthSessionFactory,
        presentationContextProvider: presentationContextProvider,
        authenticationSessionStateStore: authenticationSessionStateStore
      )
    )
  }

  override func tearDown() {
    presenter = nil
    authSession = nil
    webAuthSessionFactory = nil
    presentationContextProvider = nil
    authenticationSessionStateStore = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    presenter.resetDependencies()
    let dependencies = try presenter.getDependencies()

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
    let dependencies = try presenter.getDependencies()

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
    var capturedResult: CompletionLoginResult?
    presenter.presentAuthenticationDialog(
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
    XCTAssertEqual(capturedResult!.getURL(), url, "Should invoke the completion handler with the expected result")

    XCTAssertIdentical(
      authSession.presentationContextProvider,
      presentationContextProvider,
      "Should pass the presentation context provider to the authentication session"
    )
    XCTAssertTrue(authSession.startWasCalled, "Authentication session starts when openURL is called")
    XCTAssertEqual(
      authenticationSessionStateStore.authenticationSessionState,
      .performingLogin,
      "Session state should be set to .performinglogin after successfully starting authentication session"
    )
  }

  func testOpenURLWithCanceledSession() throws {
    var capturedResult: CompletionLoginResult?
    presenter.presentAuthenticationDialog(
      url: sampleURL,
      callbackURLScheme: sampleCallbackURLScheme
    ) { result in
      if case .cancel = result {
        capturedResult = result
      }
    }

    webAuthSessionFactory.capturedCompletionHandler?(.cancel)
    XCTAssertTrue(
      capturedResult!.isCancellation(),
      "The captured result should indicate a cancellation"
    )
    XCTAssertEqual(
      authenticationSessionStateStore.authenticationSessionState,
      .canceled,
      "Session state should be set to .canceled when the canceled login error is returned"
    )
  }

  func testOpenURLWithPresentationContextNotProvided() throws {
    var capturedResult: CompletionLoginResult?
    var capturedError: Error?
    presenter.presentAuthenticationDialog(
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
      authenticationSessionStateStore.authenticationSessionState,
      .canceled,
      "Session state should be set to .canceled when the presentation context is not provided"
    )
  }

  func testOpenURLWithPresentationContextInvalid() throws {
    var capturedResult: CompletionLoginResult?
    var capturedError: Error?
    presenter.presentAuthenticationDialog(
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
      authenticationSessionStateStore.authenticationSessionState,
      .canceled,
      "Session state should be set to .canceled when there is an invalid presentation context"
    )
  }
}
