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
  var presenter: TestAuthenticationDialogPresenter!
  var metaLogin: MetaLogin!
  var loginConfiguration: LoginConfiguration!
  var userSessionStore: TestUserSessionStore!
  var authenticationSessionStateStore: TestAuthenticationSessionStateStore!

  override func setUp() {
    super.setUp()

    loginConfiguration = LoginConfiguration(
      permissions: [.userAvatar],
      facebookAppID: "facebook_app_id",
      metaAppID: "some_meta_app_id"
    )
    userSessionStore = TestUserSessionStore()
    authenticationSessionStateStore = TestAuthenticationSessionStateStore()
    metaLogin = MetaLogin()
    presenter = TestAuthenticationDialogPresenter()
    metaLogin.setDependencies(
      .init(
        authenticationDialogPresenter: presenter,
        userSessionStore: userSessionStore,
        authenticationSessionStateStore: authenticationSessionStateStore
      )
    )
  }

  override func tearDown() {
    loginConfiguration = nil
    metaLogin = nil
    presenter = nil
    userSessionStore = nil
    authenticationSessionStateStore = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    metaLogin.resetDependencies()
    let dependencies = try metaLogin.getDependencies()

    XCTAssertTrue(
      dependencies.authenticationDialogPresenter is AuthenticationDialogPresenter,
      "A login manager uses a provided authentication web view"
    )
    XCTAssertTrue(
      dependencies.userSessionStore is UserSessionStore,
      "A login manager uses a provided LocalStorage"
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try metaLogin.getDependencies()

    XCTAssertTrue(
      dependencies.authenticationDialogPresenter is TestAuthenticationDialogPresenter,
      "Should be set to a custom authentication web view"
    )
    XCTAssertTrue(
      dependencies.userSessionStore is TestUserSessionStore,
      "A login manager uses a custom LocalStorage"
    )
  }

  func testSuccessfulLogin() throws {
    let didReceiveResponse = expectation(description: #function)
    var capturedUserSession: UserSession?
    metaLogin.logIn(configuration: loginConfiguration) { result in
      if case let .success(result) = result {
        capturedUserSession = result
      } else {
        XCTFail("Should not fail with successful login")
      }
      didReceiveResponse.fulfill()
    }

    let sampleURL = SampleURLs.LoginResponses.withDefaultParameters
    presenter.capturedCompletion?(.success(sampleURL))
    wait(for: [didReceiveResponse], timeout: 0.5)
    XCTAssertNotNil(capturedUserSession, "Should capture user session after successful login")
    XCTAssertEqual(
      capturedUserSession,
      userSessionStore.capturedUserSessionInSave,
      "Should save user session upon successful login"
    )
    XCTAssertTrue(presenter.wasPresentAuthenticationDialogCalled, "Login should call open URL")
    XCTAssertEqual(
      presenter.capturedCallbackURLScheme,
      MetaLogin.callbackURLScheme,
      "Should capture set callback URL scheme"
    )
  }

  func testLoginWithLoginResponseError() throws {
    var capturedError: Error?
    metaLogin.logIn(configuration: loginConfiguration) { result in
      if case let .failure(error) = result {
        capturedError = error
      }
    }
    presenter.capturedCompletion?(.success(SampleURLs.loginRedirect))

    presenter.capturedCompletion?(.success(SampleURLs.example))

    XCTAssertEqual(
      capturedError as? LoginError,
      LoginError.invalidIncomingURL,
      "Authentication session error should be set to assigned value"
    )
  }

  func testLoginWithCancelledLoginSession() throws {
    var capturedResult: LoginResult?
    metaLogin.logIn(configuration: loginConfiguration) { result in
      if case .cancel = result {
        capturedResult = result
      } else {
        XCTFail("Should return cancel result when login is cancelled")
      }
    }

    presenter.capturedCompletion?(.cancel)
    XCTAssertNotNil(capturedResult, "The captured result should indicate a cancellation")
  }

  func testLoginWithOpenURLError() throws {
    var capturedError: Error?
    metaLogin.logIn(configuration: loginConfiguration) { result in
      if case let .failure(error) = result {
        capturedError = error
      }
    }

    let sampleError = SampleError.WebAuthSessionCancelledError
    presenter.capturedCompletion?(.failure(sampleError))
    XCTAssertIdentical(
      capturedError as AnyObject,
      sampleError as AnyObject,
      "Authentication session error should be set to assigned value"
    )
  }

  func testMakeLoginParameters() throws {
    guard let parameters = metaLogin.makeLoginParameters(configuration: loginConfiguration)
    else {
      XCTFail("Should return dictionary of parameters with valid login configuration")
      return
    }

    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.fbAppID],
      loginConfiguration.facebookAppID,
      "Should set app ID from login configuration"
    )
    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.metaAppID],
      loginConfiguration.metaAppID,
      "Should set app ID from login configuration"
    )
    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.display],
      SampleMetaLoginParameters.display,
      "Should set default display from parameters"
    )
    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.sdk],
      SampleMetaLoginParameters.sdk,
      "Should set default sdk from parameters"
    )
    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.returnScopes],
      SampleMetaLoginParameters.returnScopes,
      "Should set default return scopes from parameters"
    )
    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.responseType],
      SampleMetaLoginParameters.responseType,
      "Should set default response type from parameters"
    )
    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.scope],
      SampleMetaLoginParameters.scope,
      "Should set default scope from parameters"
    )
    XCTAssertEqual(
      parameters[SampleMetaLoginParameters.Keys.redirectURI],
      SampleMetaLoginParameters.redirectURI,
      "Should set default redirect URI from parameters"
    )
  }

  func testLogout() async throws {
    authenticationSessionStateStore.stubbedAuthenticationSessionState = .performingLogin
    await metaLogin.logOut()
    let state = await authenticationSessionStateStore.getAuthenticationSessionState()
    XCTAssertNil(
      state,
      "AuthenticationSessionState should be set as none after user logs out"
    )
    XCTAssertTrue(
      userSessionStore.isDeleteUserSessionCalled,
      "Should delete the stored user session when a user logs out"
    )
  }

  func testLoginWithInvalidIncomingAuthenticationURL() throws {
    let loginConfiguration = LoginConfiguration(
      permissions: [.userAvatar],
      facebookAppID: "facebook_app_id",
      metaAppID: "some_meta_app_id"
    )
    var capturedError: Error?

    metaLogin.logIn(configuration: loginConfiguration) { result in
      if case let .failure(error) = result {
        capturedError = error
      }
    }

    let url = SampleURLs.example(path: "foo")
    presenter.capturedCompletion?(.success(url))
    XCTAssertNotNil(
      capturedError,
      "Should return URL error if the incoming URL does not begin with the Meta Login redirect uri"
    )
  }

  func testGetUserSession() async throws {
    let userSessionResult = await metaLogin.userSession
    XCTAssertEqual(
      userSessionStore.stubbedUserSession,
      userSessionResult,
      "The userSession variable should be consistent with cached data"
    )
  }

  func testGetUserSessionWithItemNotFoundError() async throws {
    userSessionStore.stubbedError = LocalStorageError.itemNotFound
    let userSessionResult = await metaLogin.userSession
    XCTAssertNil(
      userSessionResult,
      "The userSession should be nil when error occurs in userSessionStore get method "
    )
  }

  func testGetUserSessionWithUnhandledError() async throws {
    userSessionStore.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    let userSessionResult = await metaLogin.userSession
    XCTAssertNil(
      userSessionResult,
      "The userSession should be nil when error occurs in userSessionStore get method "
    )
  }

  func testLoginWithInvalidLoginURLCreation() throws {
    var loginConfiguration = LoginConfiguration(permissions: [.userAvatar])
    let appConfigurationInquirer = TestAppConfigurationInquirer()
    appConfigurationInquirer.metaAppID = nil
    appConfigurationInquirer.facebookAppID = nil
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    var capturedError: Error?
    metaLogin.logIn(configuration: loginConfiguration) { result in
      if case let .failure(error) = result {
        capturedError = error
      }
    }
    XCTAssertEqual(
      capturedError as? LoginError,
      LoginError.invalidURLCreation,
      "Should return error if login parameters cannot be retrieved"
    )
  }
}
