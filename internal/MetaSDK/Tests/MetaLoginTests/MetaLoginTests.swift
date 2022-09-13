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
  var metaLogin: MetaLogin!
  var webAuthenticator: TestWebAuthenticator!
  var userSessionStore: TestUserSessionStore!

  let loginConfiguration = LoginConfiguration(
    permissions: [.userAvatar],
    facebookAppID: "facebook_app_id",
    metaAppID: "some_meta_app_id"
  )

  override func setUp() {
    super.setUp()

    webAuthenticator = TestWebAuthenticator()
    userSessionStore = TestUserSessionStore()
    metaLogin = MetaLogin()
    metaLogin.setDependencies(
      .init(
        webAuthenticator: webAuthenticator,
        userSessionStore: userSessionStore
      )
    )
  }

  override func tearDown() {
    metaLogin = nil
    webAuthenticator = nil
    userSessionStore = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    metaLogin.resetDependencies()
    let dependencies = try metaLogin.getDependencies()

    XCTAssertTrue(
      dependencies.webAuthenticator is AppleWebAuthenticator,
      "A login manager uses an Apple web authenticator by default"
    )
    XCTAssertTrue(
      dependencies.userSessionStore is UserSessionStore,
      "A login manager uses a user session store by default"
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try metaLogin.getDependencies()

    XCTAssertIdentical(
      dependencies.webAuthenticator as AnyObject,
      webAuthenticator,
      "A login manager uses a custom web authenticator when provided"
    )
    XCTAssertIdentical(
      dependencies.userSessionStore as AnyObject,
      userSessionStore,
      "A login manager uses a custom user session store when provided"
    )
  }

  func testSuccessfulLogin() async throws {
    await webAuthenticator.setResponseURL(SampleURLs.LoginResponses.withDefaultParameters)

    do {
      let session = try await metaLogin.logIn(configuration: loginConfiguration)

      XCTAssertIdentical(
        session,
        userSessionStore.capturedUserSessionInSave,
        "The user session is saved upon successful login"
      )
    } catch {
      XCTFail("No error is thrown for a successful login")
    }
  }

  func testLoginWithLoginResponseError() async throws {
    await webAuthenticator.setResponseURL(SampleURLs.loginRedirect)

    do {
      try await metaLogin.logIn(configuration: loginConfiguration)
      XCTFail("An error is thrown with an invalid response URL")
    } catch LoginFailure.internal {
      // This is the expected error
    } catch {
      XCTFail("Authentication session error should be set to assigned value")
    }
  }

  func testLoginWithCancelledLoginSession() async throws {
    await webAuthenticator.setError(LoginFailure.isCanceled)

    do {
      try await metaLogin.logIn(configuration: loginConfiguration)
      XCTFail("Should return cancel result when login is cancelled")
    } catch LoginFailure.isCanceled {
      // This is the expected error
    } catch {
      XCTFail("Should return cancel result when login is cancelled")
    }
  }

  func testLoginWithOtherError() async throws {
    await webAuthenticator.setError(LoginFailure.unknown)

    do {
      try await metaLogin.logIn(configuration: loginConfiguration)
      XCTFail("Authentication session error should be set to assigned value")
    } catch LoginFailure.unknown {
      // This is the expected error
    } catch {
      XCTFail("Authentication session error should be set to assigned value")
    }
  }

  func testLoginParameters() throws {
    let parameters = try metaLogin.getLoginParameters(from: loginConfiguration)

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
    await metaLogin.logOut()

    XCTAssertTrue(
      userSessionStore.isDeleteUserSessionCalled,
      "Should delete the stored user session when a user logs out"
    )
  }

  func testLoginWithInvalidIncomingAuthenticationURL() async throws {
    let loginConfiguration = LoginConfiguration(
      permissions: [.userAvatar],
      facebookAppID: "facebook_app_id",
      metaAppID: "some_meta_app_id"
    )
    await webAuthenticator.setResponseURL(SampleURLs.example(path: "foo"))

    do {
      try await metaLogin.logIn(configuration: loginConfiguration)
      XCTFail("Should return URL error if the incoming URL does not begin with the Meta Login redirect uri")
    } catch {
      // Expecting an error to be thrown
    }
  }

  func testGettingUserSession() async throws {
    let userSession = await metaLogin.userSession
    XCTAssertIdentical(
      userSession,
      userSessionStore.stubbedUserSession,
      "The userSession variable should be consistent with cached data"
    )
  }

  func testGettingUserSessionWithItemNotFoundError() async {
    userSessionStore.stubbedError = LocalStorageError.itemNotFound
    let userSession = await metaLogin.userSession

    XCTAssertNil(
      userSession,
      "The userSession should be nil when error occurs in userSessionStore get method "
    )
  }

  func testGettingUserSessionWithUnhandledError() async {
    userSessionStore.stubbedError = LocalStorageError.unhandledError(status: "foo")
    let userSession = await metaLogin.userSession

    XCTAssertNil(
      userSession,
      "The userSession should be nil when error occurs in userSessionStore get method "
    )
  }

  func testLoginWithInvalidLoginURLCreation() async throws {
    var loginConfiguration = LoginConfiguration(permissions: [.userAvatar])
    let appConfigurationInquirer = TestAppConfigurationInquirer()
    appConfigurationInquirer.metaAppID = nil
    appConfigurationInquirer.facebookAppID = nil
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    do {
      try await metaLogin.logIn(configuration: loginConfiguration)
      XCTFail("Should return error if login parameters cannot be retrieved")
    } catch LoginFailure.internal {
      // This is the expected error
    } catch {
      XCTFail("Should return error if login parameters cannot be retrieved")
    }
  }
}
