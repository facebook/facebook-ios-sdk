/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

// swiftlint:disable line_length
class LoginManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var claims: [String: Any]!
  var internalUtility: TestInternalUtility!
  var loginManager: LoginManager!
  var keychainStoreFactory: TestKeychainStoreFactory!
  var keychainStore: TestKeychainStore!
  var graphRequestConnectionFactory: TestGraphRequestConnectionFactory!
  var connection: TestGraphRequestConnection!
  var urlOpener: TestURLOpener!
  var settings: TestSettings!
  var loginCompleter: TestLoginCompleter!
  var loginCompleterFactory: TestLoginCompleterFactory!
  var testUser: Profile!
  // swiftlint:enable implicitly_unwrapped_optional

  let appID = "7391628439"
  let challenge = "a =bcdef"
  let nonce = "fedcb =a"
  let jti = "a jti is just any string"
  let header = [
    "alg": "RS256",
    "typ": "JWT",
    "kid": "abcd1234",
  ]
  // @lint-ignore FBOBJCDISCOURAGEDFUNCTION
  let formatter = DateFormatter()
  let sampleURL = URL(string: "https://example.com")! // swiftlint:disable:this force_unwrapping

  override func setUp() {
    super.setUp()

    resetClassDependencies()

    formatter.dateFormat = "MM/dd/yyyy"

    ApplicationDelegate.shared.application(
      UIApplication.shared,
      didFinishLaunchingWithOptions: [:]
    )

    internalUtility = TestInternalUtility()
    keychainStore = TestKeychainStore()
    keychainStoreFactory = TestKeychainStoreFactory()
    keychainStoreFactory.stubbedKeychainStore = keychainStore
    connection = TestGraphRequestConnection()
    graphRequestConnectionFactory = TestGraphRequestConnectionFactory(stubbedConnection: connection)
    urlOpener = TestURLOpener()
    settings = TestSettings()
    settings.appID = appID
    loginCompleter = TestLoginCompleter()
    loginCompleterFactory = TestLoginCompleterFactory(stubbedLoginCompleter: loginCompleter)

    loginManager = LoginManager(
      internalUtility: internalUtility,
      keychainStoreFactory: keychainStoreFactory,
      accessTokenWallet: TestAccessTokenWallet.self,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
      authenticationToken: TestAuthenticationTokenWallet.self,
      profile: TestProfileProvider.self,
      urlOpener: urlOpener,
      settings: settings,
      loginCompleterFactory: loginCompleterFactory
    )
    testUser = createProfile()
    TestProfileProvider.current = testUser

    AuthenticationToken.current = nil
    TestAccessTokenWallet.currentAccessToken = nil

    claims = createClaims()
  }

  func createProfile() -> Profile {
    Profile(
      userID: "1234",
      firstName: "Test",
      middleName: "Middle",
      lastName: "User",
      name: "Test User",
      linkURL: URL(string: "https://www.facebook.com"),
      refreshDate: nil,
      imageURL: URL(string: "https://www.facebook.com/some_picture"),
      email: "email@email.com",
      friendIDs: ["123", "456"],
      birthday: formatter.date(from: "01/01/1990"),
      ageRange: UserAgeRange(from: ["min": 21]),
      hometown: Location(
        from: [
          "id": "112724962075996",
          "name": "Martinez, California"
        ]
      ),
      location: Location(
        from: [
          "id": "110843418940484",
          "name": "Seattle, Washington"
        ]
      ),
      gender: "male",
      isLimited: false
    )
  }

  func createClaims() -> [String: Any] {
    let currentTime = Date().timeIntervalSince1970
    return [
      "iss": "https://facebook.com/dialog/oauth",
      "aud": appID,
      "nonce": nonce,
      "exp": currentTime + 60 * 60 * 48, // 2 days later
      "iat": currentTime - 60, // 1 min ago
      "jti": jti,
      "sub": "1234",
      "name": "Test User",
      "given_name": "Test",
      "middle_name": "Middle",
      "family_name": "User",
      "email": "email@email.com",
      "picture": "https://www.facebook.com/some_picture",
      "user_friends": ["123", "456"],
      "user_birthday": "01/01/1990",
      "user_age_range": ["min": 21],
      "user_hometown": ["id": "112724962075996", "name": "Martinez, California"],
      "user_location": ["id": "110843418940484", "name": "Seattle, Washington"],
      "user_gender": "male",
      "user_link": "https://www.facebook.com",
    ]
  }

  override func tearDown() {
    claims = nil
    internalUtility = nil
    loginManager = nil
    keychainStoreFactory = nil
    keychainStore = nil
    graphRequestConnectionFactory = nil
    connection = nil
    urlOpener = nil
    settings = nil
    loginCompleter = nil
    loginCompleterFactory = nil

    resetClassDependencies()

    super.tearDown()
  }

  func resetClassDependencies() {
    Profile.reset()
    AccessToken.resetClassDependencies()
    AccessToken.resetCurrentAccessTokenCache()
    AuthenticationToken.resetCurrentAuthenticationTokenCache()
  }

  func testDefaultDependencies() {
    let loginManager = LoginManager()

    XCTAssertTrue(loginManager.internalUtility is InternalUtility)
    XCTAssertTrue(loginManager.keychainStore.self is KeychainStore)
    XCTAssertTrue(loginManager.accessTokenWallet is AccessToken.Type)
    XCTAssertTrue(loginManager.graphRequestConnectionFactory is GraphRequestConnectionFactory)
    XCTAssertTrue(loginManager.authenticationToken is AuthenticationToken.Type)
    XCTAssertTrue(loginManager.profile is Profile.Type)
    XCTAssertTrue(loginManager.urlOpener is BridgeAPI)
    XCTAssertTrue(loginManager.settings is Settings)
    XCTAssertTrue(loginManager.loginCompleterFactory is LoginCompleterFactory)
  }

  // MARK: Opening URL

  func testOpenURLUsesLoginCompleterFactory() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#granted_scopes=public_profile&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949&state=%7B%22challenge%22%3A%22a%2520%253Dbcdef%22%7D")
    )
    _ = loginManager.application(nil, open: url, sourceApplication: "com.apple.mobilesafari", annotation: nil)

    XCTAssertEqual(
      loginCompleterFactory.capturedAppID,
      settings.appID,
      "Should create a login completer using the expected app identifier"
    )
    XCTAssertEqual(
      loginCompleterFactory.capturedURLParameters["access_token"] as? String,
      "sometoken",
      "Should create a login completer using the parameters parsed from the url"
    )
    XCTAssertEqual(
      loginCompleterFactory.capturedURLParameters["denied_scopes"] as? String,
      "email,user_friends",
      "Should create a login completer using the parameters parsed from the url"
    )
    XCTAssertEqual(
      loginCompleterFactory.capturedURLParameters["expires_in"] as? String,
      "5183949",
      "Should create a login completer using the parameters parsed from the url"
    )
    XCTAssertEqual(
      loginCompleterFactory.capturedURLParameters["granted_scopes"] as? String,
      "public_profile",
      "Should create a login completer using the parameters parsed from the url"
    )
    XCTAssertEqual(
      loginCompleterFactory.capturedURLParameters["signed_request"] as? String,
      "ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0",
      "Should create a login completer using the parameters parsed from the url"
    )
    XCTAssertEqual(
      loginCompleterFactory.capturedURLParameters["state"] as? String,
      #"{"challenge":"a%20%3Dbcdef"}"#,
      "Should create a login completer using the parameters parsed from the url"
    )
    XCTAssertEqual(
      loginCompleterFactory.capturedURLParameters["user_id"] as? String,
      "123",
      "Should create a login completer using the parameters parsed from the url"
    )
    XCTAssertTrue(
      loginCompleterFactory.capturedAuthenticationTokenCreator is AuthenticationTokenFactory,
      "Should create a login completer using the expected authentication token factory"
    )
  }

  // MARK: Completing Authentication

  func testCompletingAuthenticationWithMixedPermissionsWithExpectedChallenge() throws {
    var capturedResult: LoginManagerLoginResult?
    loginManager.setRequestedPermissions(["email", "user_friends"])
    loginManager.handler = { result, _ in
      capturedResult = result
    }

    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let parameters = LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    parameters.userID = "123"

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    let result = try XCTUnwrap(capturedResult)
    XCTAssertFalse(result.isCancelled)
    let tokenAfterAuth = try XCTUnwrap(TestAccessTokenWallet.currentAccessToken)
    XCTAssertEqual(
      tokenAfterAuth.tokenString,
      "accessTokenString"
    )
    XCTAssertEqual(
      tokenAfterAuth.userID,
      "123",
      "failed to parse userID"
    )
    XCTAssertEqual(
      tokenAfterAuth.permissions,
      ["public_profile"],
      "unexpected permissions"
    )
    XCTAssertEqual(
      result.grantedPermissions,
      ["public_profile"],
      "unexpected permissions"
    )
    let expectedDeclined = ["email", "user_friends"]
    XCTAssertEqual(
      tokenAfterAuth.declinedPermissions,
      Set(expectedDeclined.map(Permission.init)),
      "unexpected permissions"
    )
    XCTAssertEqual(
      result.declinedPermissions,
      Set(expectedDeclined),
      "unexpected permissions"
    )
    XCTAssertNil(result.authenticationToken)
    XCTAssertNil(keychainStore.keychainDictionary["expected_login_challenge"])
    XCTAssertTrue(keychainStore.wasStringForKeyCalled)
  }

  func testCompletingAuthenticationWithCancellation() {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    let parameters = LoginCompletionParameters()
    parameters.error = SampleError()

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    XCTAssertEqual(
      TestAccessTokenWallet.currentAccessToken,
      SampleAccessTokens.validToken,
      "Handling a cancelled auth attempt should not affect the current access token"
    )
    XCTAssertNil(capturedResult)
    XCTAssertNotNil(capturedError)
  }

  // verify basic case of first login and no declined permissions.
  func testCompletingAuthenticationWithoutDeclines() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#granted_scopes=public_profile&denied_scopes=&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949")
    )
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken

    _ = loginManager.application(nil, open: url, sourceApplication: "com.apple.mobilesafari", annotation: nil)

    let completerHandler = try XCTUnwrap(loginCompleter.capturedCompletionHandler)

    let parameters = LoginCompletionParameters()
    parameters.appID = appID
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])
    parameters.declinedPermissions = []
    parameters.accessTokenString = "sometoken"
    completerHandler(parameters)

    let actualToken = try XCTUnwrap(TestAccessTokenWallet.currentAccessToken)
    XCTAssertEqual(actualToken.userID, "user123", "failed to parse userID")
    XCTAssertEqual(actualToken.declinedPermissions, [], "unexpected permissions")
  }

  // verify that recentlyDeclined is a subset of requestedPermissions (i.e., other declined permissions are not in recentlyDeclined)
  func testCompletingAuthenticationWithRecentlyDeclinedPermissions() throws {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }
    loginManager.setRequestedPermissions(["user_friends"])

    _ = keychainStore.setString(challenge, forKey: "expected_login_challenge", accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)

    let parameters = LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["user_likes", "user_friends"])

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    let result = try XCTUnwrap(capturedResult)
    XCTAssertFalse(result.isCancelled)
    XCTAssertEqual(result.declinedPermissions, Set(["user_friends"]))
    XCTAssertEqual(result.grantedPermissions, Set(["public_profile"]))

    XCTAssertNil(keychainStore.keychainDictionary["expected_login_challenge"])
    XCTAssertTrue(keychainStore.wasStringForKeyCalled)

    XCTAssertNil(capturedError)
  }

  func testCompletingAuthenticationWithoutGrantedPermissions() throws {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }
    loginManager.setRequestedPermissions(["user_friends"])

    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let parameters = LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["user_likes", "user_friends"])

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    let result = try XCTUnwrap(capturedResult)
    XCTAssertNil(result.token)
    XCTAssertNil(capturedError)
    XCTAssertNil(keychainStore.keychainDictionary["expected_login_challenge"])
    XCTAssertTrue(keychainStore.wasStringForKeyCalled)
  }

  // verify that a reauth for already granted permissions is not treated as a cancellation.
  func testCompletingReauthenticationSamePermissionsIsNotCancelled() throws {
    let existingToken = SampleAccessTokens.create(withPermissions: ["public_profile", "read_stream"])
    TestAccessTokenWallet.currentAccessToken = existingToken

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }
    loginManager.setRequestedPermissions(["public_profile", "read_stream"])

    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let parameters = LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile", "read_stream"])

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    XCTAssertEqual(
      connection.capturedRequest?.graphPath,
      "me",
      "Should create a graph request with the expected graph path"
    )
    connection.capturedCompletion?(nil, ["id": existingToken.userID], nil)

    let result = try XCTUnwrap(capturedResult)
    XCTAssertNil(capturedError)
    XCTAssertFalse(result.isCancelled)
  }

  func testCompletingAuthenticationWithBadChallenge() {
    // Sets challenge that will not be matched by the parameters
    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.setRequestedPermissions(["email", "user_friends"])

    let parameters = LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = "someotherchallenge"
    parameters.authenticationTokenString = "sometoken"
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["user_likes", "user_friends"])

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    XCTAssertNotNil(capturedError)
    XCTAssertNil(capturedResult)
  }

  func testCompletingAuthenticationWithNoChallengeAndError() {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.setRequestedPermissions(["email", "user_friends"])

    let parameters = LoginCompletionParameters()
    parameters.error = SampleError()

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    XCTAssertNil(capturedResult)
    XCTAssertNotNil(capturedError)
  }

  func testOpenURLWithNonFacebookURL() throws {
    let url = try XCTUnwrap(
      URL(string: "test://test?granted_scopes=public_profile&access_token=sometoken&expires_in=5183949")
    )
    loginManager.state = .performingLogin

    XCTAssertFalse(loginManager.application(nil, open: url, sourceApplication: "com.apple.mobilesafari", annotation: nil))

    XCTAssertNil(loginCompleter.capturedCompletionHandler)
    XCTAssertEqual(
      loginManager.state,
      .idle,
      "For verifying if handleImplicitCancelOfLogIn is being called we check if the state is in idle"
    )
  }

  func testOpenURLAuthWithAuthenticationToken() throws {
    _ = keychainStore.setString(
      nonce,
      forKey: "expected_login_nonce",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let rawClaims = try XCTUnwrap(claims)
    let claimsData = try JSONSerialization.data(withJSONObject: rawClaims, options: [])
    let encodedClaims = try XCTUnwrap(Base64.encode(claimsData))
    let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
    let encodedHeader = try XCTUnwrap(Base64.encode(headerData))

    let tokenString = "\(encodedHeader).\(encodedClaims).signature"

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.setRequestedPermissions(["email", "user_friends"])

    let parameters = LoginCompletionParameters()
    parameters.authenticationTokenString = tokenString
    parameters.authenticationToken = AuthenticationToken(tokenString: tokenString, nonce: nonce)
    parameters.challenge = challenge
    parameters.profile = testUser
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    XCTAssertNil(capturedError)
    let result = try XCTUnwrap(capturedResult)
    XCTAssertFalse(result.isCancelled)

    let token = try XCTUnwrap(result.authenticationToken)
    validate(authenticationToken: token, expectedTokenString: tokenString)

    XCTAssertNil(keychainStore.keychainDictionary["expected_login_challenge"])
    XCTAssertTrue(keychainStore.wasStringForKeyCalled)

    let profile = try XCTUnwrap(TestProfileProvider.current)
    try validate(profile: profile)

    XCTAssertNil(result.token)
  }

  func testCompletingAuthenticationWithAuthenticationTokenWithAccessToken() throws {
    _ = keychainStore.setString(
      nonce,
      forKey: "expected_login_nonce",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let rawClaims = try XCTUnwrap(claims)
    let claimsData = try JSONSerialization.data(withJSONObject: rawClaims, options: [])
    let encodedClaims = try XCTUnwrap(Base64.encode(claimsData))
    let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
    let encodedHeader = try XCTUnwrap(Base64.encode(headerData))

    let tokenString = "\(encodedHeader).\(encodedClaims).signature"

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }
    loginManager.setRequestedPermissions(["email", "user_friends"])

    let parameters = LoginCompletionParameters()
    parameters.authenticationTokenString = tokenString
    parameters.authenticationToken = AuthenticationToken(tokenString: tokenString, nonce: nonce)
    parameters.challenge = challenge
    parameters.profile = testUser
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])

    loginManager.completeAuthentication(parameters, expectChallenge: true)

    let result = try XCTUnwrap(capturedResult)

    XCTAssertFalse(result.isCancelled)

    let token = try XCTUnwrap(result.authenticationToken)
    validate(authenticationToken: token, expectedTokenString: tokenString)

    XCTAssertNil(keychainStore.keychainDictionary["expected_login_challenge"])
    XCTAssertTrue(keychainStore.wasStringForKeyCalled)

    let profile = try XCTUnwrap(TestProfileProvider.current)
    try validate(profile: profile)

    XCTAssertNil(capturedError)
  }

  func testApplicationDidBecomeActiveWhileLogin() {
    loginManager.state = .performingLogin
    loginManager.applicationDidBecomeActive(UIApplication.shared)

    XCTAssertEqual(loginManager.state, .idle)
  }

  func testIsAuthenticationURL() {
    XCTAssertFalse(
      loginManager.isAuthenticationURL(
        URL(string: "https://www.facebook.com/some/test/url")! // swiftlint:disable:this force_unwrapping
      )
    )
    XCTAssertTrue(
      loginManager.isAuthenticationURL(
        URL(string: "https://www.facebook.com/v9.0/dialog/oauth/?test=test")! // swiftlint:disable:this force_unwrapping
      )
    )
    XCTAssertFalse(
      loginManager.isAuthenticationURL(
        URL(string: "123")! // swiftlint:disable:this force_unwrapping
      )
    )
  }

  func testShouldStopPropagationOfURL() {
    var url = URL(string: "fb\(appID)://no-op/test/")! // swiftlint:disable:this force_unwrapping
    XCTAssertTrue(loginManager.shouldStopPropagation(of: url))

    url = URL(string: "fb\(appID)://")! // swiftlint:disable:this force_unwrapping
    XCTAssertFalse(loginManager.shouldStopPropagation(of: url))

    url = URL(string: "https://no-op/")! // swiftlint:disable:this force_unwrapping
    XCTAssertFalse(loginManager.shouldStopPropagation(of: url))
  }

  func testLoginWithSFVC() {
    internalUtility.stubbedAppURL = sampleURL
    internalUtility.stubbedFacebookURL = sampleURL

    loginManager.logIn(withPermissions: ["public_profile"], from: UIViewController()) { _, _ in }

    XCTAssertTrue(
      urlOpener.wasOpenURLWithSVCCalled,
      "openURLWithSafariViewController should be called"
    )
    XCTAssertFalse(
      urlOpener.wasOpenURLWithoutSVCCalled,
      "openURL should not be called"
    )
    XCTAssertTrue(
      loginManager.usedSFAuthSession,
      "If useSafariViewController is YES, _usedSFAuthSession should be YES and openURLWithSafariViewController should be invoked"
    )

    XCTAssertNotNil(urlOpener.viewController)
  }

  func testCallingLoginWithStateChange() {
    internalUtility.isFacebookAppInstalled = false
    loginManager.usedSFAuthSession = false
    loginManager.state = .start

    var didInvokeCompletionSynchronously = false
    loginManager.logIn(withPermissions: ["public_profile"], from: UIViewController()) { _, _ in
      didInvokeCompletionSynchronously = true
    }

    XCTAssertFalse(didInvokeCompletionSynchronously)
  }

  // MARK: Login Parameters

  func testLoginTrackingEnabledLoginParams() throws {
    let configuration = LoginConfiguration(
      permissions: ["public_profile", "email"],
      tracking: .enabled
    )
    let logger = try XCTUnwrap(
      LoginManagerLogger(
        loggingToken: "123",
        tracking: .enabled
      )
    )

    internalUtility.stubbedAppURL = sampleURL
    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        with: configuration,
        loggingToken: "",
        logger: logger,
        authMethod: "sfvc_auth"
      )
    )

    try validateCommonLoginParameters(parameters)
    XCTAssertEqual(
      parameters["response_type"],
      "id_token,token_or_nonce,signed_request,graph_domain"
    )
    let scopes = parameters["scope"]?
      .split(separator: ",")
      .sorted()
      .joined(separator: ",")
    XCTAssertEqual(
      scopes,
      "email,openid,public_profile"
    )
    XCTAssertNotNil(parameters["nonce"])
    XCTAssertNil(parameters["tp"], "Regular login should not send a tracking parameter")
    let rawState = try XCTUnwrap(parameters["state"])
    let state = try BasicUtility.object(forJSONString: rawState) as? [String: Any]
    XCTAssertEqual(
      state?["3_method"] as? String,
      "sfvc_auth"
    )
    XCTAssertEqual(
      parameters["auth_type"],
      LoginAuthType.rerequest.rawValue
    )
  }

  func testLoginTrackingLimitedLoginParams() throws {
    let configuration = LoginConfiguration(
      permissions: ["public_profile", "email"],
      tracking: .limited,
      nonce: "some_nonce"
    )
    internalUtility.stubbedAppURL = sampleURL
    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        with: configuration,
        loggingToken: "",
        logger: nil,
        authMethod: "browser_auth"
      )
    )

    try validateCommonLoginParameters(parameters)

    XCTAssertEqual(
      parameters["response_type"],
      "id_token,graph_domain"
    )
    let scopes = parameters["scope"]?
      .split(separator: ",")
      .sorted()
      .joined(separator: ",")
    XCTAssertEqual(
      scopes,
      "email,openid,public_profile"
    )
    XCTAssertEqual(
      parameters["nonce"],
      "some_nonce"
    )
    XCTAssertEqual(
      parameters["tp"],
      "ios_14_do_not_track"
    )
    let rawState = try XCTUnwrap(parameters["state"])
    let state = try BasicUtility.object(forJSONString: rawState) as? [String: Any]
    XCTAssertEqual(
      state?["3_method"] as? String,
      "browser_auth"
    )
    XCTAssertEqual(
      parameters["auth_type"],
      LoginAuthType.rerequest.rawValue
    )
  }

  func testLoginParamsWithNilConfiguration() {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    let parameters = loginManager.logInParameters(
      with: nil,
      loggingToken: nil,
      logger: nil,
      authMethod: "sfvc_auth"
    )

    XCTAssertNil(capturedResult)
    XCTAssertNotNil(capturedError)
    XCTAssertNil(parameters)
  }

  func testLoginParamsWithNilAuthType() throws {
    let configuration = LoginConfiguration(
      permissions: ["public_profile", "email"],
      tracking: .enabled,
      messengerPageId: nil,
      authType: nil
    )
    let logger = LoginManagerLogger(loggingToken: "123", tracking: .enabled)

    internalUtility.stubbedAppURL = sampleURL

    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        with: configuration,
        loggingToken: nil,
        logger: logger,
        authMethod: "sfvc_auth"
      )
    )

    try validateCommonLoginParameters(parameters)
    XCTAssertEqual(
      parameters["response_type"],
      "id_token,token_or_nonce,signed_request,graph_domain"
    )
    let scopes = parameters["scope"]?
      .split(separator: ",")
      .sorted()
      .joined(separator: ",")
    XCTAssertEqual(
      scopes,
      "email,openid,public_profile"
    )
    XCTAssertNotNil(parameters["nonce"])
    XCTAssertNil(
      parameters["tp"],
      "Regular login should not send a tracking parameter"
    )
    let rawState = try XCTUnwrap(parameters["state"])
    let state = try BasicUtility.object(forJSONString: rawState) as? [String: Any]
    XCTAssertEqual(state?["3_method"] as? String, "sfvc_auth")
    XCTAssertNil(parameters["auth_type"])
  }

  func testLoginParamsWithExplicitlySetAuthType() throws {
    let configuration = LoginConfiguration(
      permissions: ["public_profile", "email"],
      tracking: .enabled,
      messengerPageId: nil,
      authType: .reauthorize
    )
    let logger = LoginManagerLogger(loggingToken: "123", tracking: .enabled)
    internalUtility.stubbedAppURL = sampleURL

    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        with: configuration,
        loggingToken: nil,
        logger: logger,
        authMethod: "sfvc_auth"
      )
    )

    try validateCommonLoginParameters(parameters)

    XCTAssertEqual(
      parameters["response_type"],
      "id_token,token_or_nonce,signed_request,graph_domain"
    )
    let scopes = parameters["scope"]?
      .split(separator: ",")
      .sorted()
      .joined(separator: ",")
    XCTAssertEqual(
      scopes,
      "email,openid,public_profile"
    )
    XCTAssertNotNil(parameters["nonce"])
    XCTAssertNil(parameters["tp"], "Regular login should not send a tracking parameter")
    let rawState = try XCTUnwrap(parameters["state"])
    let state = try BasicUtility.object(forJSONString: rawState) as? [String: Any]
    XCTAssertEqual(state?["3_method"] as? String, "sfvc_auth")
    XCTAssertEqual(
      parameters["auth_type"],
      LoginAuthType.reauthorize.rawValue
    )
  }

  func testLogInParametersFromNonAuthenticationURL() throws {
    let url = try XCTUnwrap(
      URL(string: "myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22fb_login%22%3A%22%7B%5C%22granted_scopes%5C%22%3A%5C%22public_profile%5C%22%2C%5C%22denied_scopes%5C%22%3A%5C%22%5C%22%2C%5C%22signed_request%5C%22%3A%5C%22ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0%5C%22%2C%5C%22nonce%5C%22%3A%5C%22someNonce%5C%22%2C%5C%22data_access_expiration_time%5C%22%3A%5C%221607374566%5C%22%2C%5C%22expires_in%5C%22%3A%5C%225183401%5C%22%7D%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D")
    )

    let parameters = try XCTUnwrap(loginManager.logInParameters(from: url))

    XCTAssertEqual(parameters["nonce"], "someNonce")
    XCTAssertEqual(parameters["granted_scopes"], "public_profile")
    XCTAssertEqual(parameters["denied_scopes"], "")
  }

  // MARK: logInWithURL

  func testLogInWithURLFailWithInvalidLoginData() throws {
    let urlWithInvalidLoginData = try XCTUnwrap(
      URL(string: "myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22fb_login%22%3A%22invalid%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D")
    )

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.logIn(url: urlWithInvalidLoginData) { result, error in
      capturedResult = result
      capturedError = error
    }

    XCTAssertNil(capturedResult)
    XCTAssertNotNil(capturedError)
  }

  func testLogInWithURLFailWithNoLoginData() throws {
    let urlWithNoLoginData = try XCTUnwrap(
      URL(string: "myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22some_param%22%3A%22some_value%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D")
    )

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.logIn(url: urlWithNoLoginData) { result, error in
      capturedResult = result
      capturedError = error
    }

    XCTAssertNil(capturedResult)
    XCTAssertNotNil(capturedError)
  }

  // MARK: Logout

  func testLogout() {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    TestAuthenticationTokenWallet.currentAuthenticationToken = SampleAuthenticationToken.validToken
    TestProfileProvider.current = testUser

    loginManager.logOut()

    XCTAssertNil(TestAccessTokenWallet.currentAccessToken)
    XCTAssertNil(TestAuthenticationTokenWallet.currentAuthenticationToken)
    XCTAssertNil(TestProfileProvider.current)
  }

  // MARK: Keychain Store

  func testStoreExpectedNonce() {
    loginManager.storeExpectedNonce("some_nonce")
    XCTAssertEqual(loginManager.keychainStore.string(forKey: "expected_login_nonce"), "some_nonce")

    loginManager.storeExpectedNonce(nil)
    XCTAssertNil(loginManager.keychainStore.string(forKey: "expected_login_nonce"))
  }

  // MARK: Reauthorization

  func testReauthorizingWithoutAccessToken() {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.reauthorizeDataAccess(from: UIViewController()) { result, error in
      capturedResult = result
      capturedError = error
    }
    let error = capturedError as NSError?
    XCTAssertNil(capturedResult, "Should not have a result when reauthorizing without a current access token")
    XCTAssertEqual(error?.domain, LoginErrorDomain)
    XCTAssertEqual(error?.code, LoginError.missingAccessToken.rawValue)
  }

  func testReauthorizingWithAccessToken() {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken

    XCTAssertNil(loginManager.configuration)

    loginManager.reauthorizeDataAccess(from: UIViewController()) { _, _ in }

    XCTAssertNotNil(
      loginManager.configuration,
      """
      Reauthorizing data access for an available access token should log in.
      We are using the existence of the configuration created during the login flow as a proxy that this happened.
      """
    )
    XCTAssertEqual(loginManager.configuration?.tracking, .enabled)
    XCTAssertEqual(loginManager.configuration?.requestedPermissions, [])
    XCTAssertNotNil(loginManager.configuration?.nonce)
  }

  func testReauthorizingWithInvalidStartState() {
    loginManager.state = .start

    loginManager.reauthorizeDataAccess(from: UIViewController()) { _, _ in
      XCTFail("Should not actually reauthorize and call the handler in this test")
    }

    XCTAssertTrue(connection.capturedRequests.isEmpty)
    XCTAssertFalse(loginManager.state == .idle)
  }

  // MARK: Permissions

  func testRecentlyGrantedPermissionsWithoutPreviouslyGrantedOrRequestedPermissions() throws {
    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    let recentlyGrantedPermissions = loginManager.recentlyGrantedPermissions(fromGrantedPermissions: grantedPermissions)
    XCTAssertEqual(recentlyGrantedPermissions, grantedPermissions)
  }

  func testRecentlyGrantedPermissionsWithPreviouslyGrantedPermissions() throws {
    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken

    let recentlyGrantedPermissions = loginManager.recentlyGrantedPermissions(fromGrantedPermissions: grantedPermissions)
    XCTAssertEqual(recentlyGrantedPermissions, grantedPermissions)
  }

  func testRecentlyGrantedPermissionsWithRequestedPermissions() throws {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.create(withPermissions: [])

    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    loginManager.setRequestedPermissions(["user_friends"])

    let recentlyGrantedPermissions = loginManager.recentlyGrantedPermissions(fromGrantedPermissions: grantedPermissions)
    XCTAssertEqual(recentlyGrantedPermissions, grantedPermissions)
  }

  func testRecentlyGrantedPermissionsWithPreviouslyGrantedAndRequestedPermissions() throws {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.create(withPermissions: ["email"])

    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    loginManager.setRequestedPermissions(["user_friends"])

    let recentlyGrantedPermissions = loginManager.recentlyGrantedPermissions(fromGrantedPermissions: grantedPermissions)
    let expectedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["user_friends"])
    )
    XCTAssertEqual(recentlyGrantedPermissions, expectedPermissions)
  }

  func testRecentlyDeclinedPermissionsWithoutRequestedPermissions() throws {
    let declinedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )

    let recentlyDeclinedPermissions = loginManager.recentlyDeclinedPermissions(fromDeclinedPermissions: declinedPermissions)
    XCTAssertTrue(recentlyDeclinedPermissions.isEmpty)
  }

  func testRecentlyDeclinedPermissionsWithRequestedPermissions() throws {
    let declinedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    loginManager.setRequestedPermissions(["user_friends"])

    let recentlyDeclinedPermissions = loginManager.recentlyDeclinedPermissions(fromDeclinedPermissions: declinedPermissions)
    let expectedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["user_friends"])
    )
    XCTAssertEqual(recentlyDeclinedPermissions, expectedPermissions)
  }

  // MARK: Reauthentication

  func testValidateReauthenticationGraphRequestCreation() {
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: nil,
      isCancelled: false,
      grantedPermissions: [],
      declinedPermissions: []
    )

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, result: result)

    XCTAssertEqual(
      connection.capturedRequest?.graphPath,
      "me",
      "Should create a graph request with the expected graph path"
    )
    XCTAssertEqual(
      connection.capturedRequest?.tokenString,
      SampleAccessTokens.validToken.tokenString,
      "Should create a graph request with the expected access token string"
    )
    XCTAssertEqual(
      connection.capturedRequest?.flags,
      [.doNotInvalidateTokenOnError, .disableErrorRecovery],
      "The graph request should not invalidate the token on error or disable error recovery"
    )
  }

  func testValidateReauthenticationCompletionWithError() {
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: nil,
      isCancelled: false,
      grantedPermissions: [],
      declinedPermissions: []
    )

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, result: result)
    connection.capturedCompletion?(nil, nil, SampleError())

    XCTAssertNotNil(capturedError)
    XCTAssertNil(capturedResult)
  }

  func testValidateReauthenticationCompletionWithMatchingUserID() {
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: nil,
      isCancelled: false,
      grantedPermissions: [],
      declinedPermissions: []
    )

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, result: result)
    connection.capturedCompletion?(nil, ["id": SampleAccessTokens.validToken.userID], nil)

    XCTAssertNil(capturedError)
    XCTAssertEqual(capturedResult, result)
  }

  func testValidateReauthenticationCompletionWithMismatchedUserID() {
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: nil,
      isCancelled: false,
      grantedPermissions: [],
      declinedPermissions: []
    )

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, result: result)
    connection.capturedCompletion?(nil, ["id": "456"], nil)

    XCTAssertNotNil(capturedError)
    XCTAssertNil(capturedResult)
  }

  // MARK: isPerformingLogin

  func testIsPerformingLoginWhenIdle() {
    loginManager.state = .idle
    XCTAssertFalse(loginManager.isPerformingLogin)
  }

  func testIsPerformingLoginWhenStarted() {
    loginManager.state = .start
    XCTAssertFalse(loginManager.isPerformingLogin)
  }

  func testIsPerformingLoginWhenPerformingLogin() {
    loginManager.state = .performingLogin
    XCTAssertTrue(loginManager.isPerformingLogin)
  }

  // MARK: - Helpers

  func validate(
    authenticationToken: AuthenticationToken,
    expectedTokenString: String
  ) {
    XCTAssertNotNil(authenticationToken, "An Authentication token should be created after successful login")
    XCTAssertEqual(
      authenticationToken.tokenString,
      expectedTokenString,
      "A raw authentication token string should be stored"
    )
    XCTAssertEqual(
      authenticationToken.nonce,
      nonce,
      "The nonce claims in the authentication token should be stored"
    )
  }

  func validate(profile: Profile) throws {
    XCTAssertNotNil(profile, "user profile should be updated")
    XCTAssertEqual(
      profile.name,
      claims["name"] as? String,
      "failed to parse user name"
    )
    XCTAssertEqual(
      profile.firstName,
      claims["given_name"] as? String,
      "failed to parse user first name"
    )
    XCTAssertEqual(
      profile.middleName,
      claims["middle_name"] as? String,
      "failed to parse user middle name"
    )
    XCTAssertEqual(
      profile.lastName,
      claims["family_name"] as? String,
      "failed to parse user last name"
    )
    XCTAssertEqual(
      profile.userID,
      claims["sub"] as? String,
      "failed to parse userID"
    )
    XCTAssertEqual(
      profile.imageURL?.absoluteString,
      claims["picture"] as? String,
      "failed to parse user profile picture"
    )
    XCTAssertEqual(
      profile.email,
      claims["email"] as? String,
      "failed to parse user email"
    )
    XCTAssertEqual(
      profile.friendIDs,
      claims["user_friends"] as? [String],
      "failed to parse user friends"
    )
    // @lint-ignore FBOBJCDISCOURAGEDFUNCTION
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy"
    let birthday = try XCTUnwrap(profile.birthday)
    XCTAssertEqual(
      formatter.string(from: birthday),
      claims["user_birthday"] as? String,
      "failed to parse user birthday"
    )
    let ageRange = try XCTUnwrap(claims["user_age_range"] as? [String: NSNumber])
    XCTAssertEqual(
      profile.ageRange,
      UserAgeRange(from: ageRange),
      "failed to parse user age range"
    )
    let hometown = try XCTUnwrap(claims["user_hometown"] as? [String: String])
    XCTAssertEqual(
      profile.hometown,
      Location(from: hometown),
      "failed to parse user hometown"
    )
    let location = try XCTUnwrap(claims["user_location"] as? [String: String])
    XCTAssertEqual(
      profile.location,
      Location(from: location),
      "failed to parse user location"
    )
    let gender = try XCTUnwrap(claims["user_gender"] as? String)
    XCTAssertEqual(
      profile.gender,
      gender,
      "failed to parse user gender"
    )
    let rawLink = try XCTUnwrap(claims["user_link"] as? String)
    let link = try XCTUnwrap(URL(string: rawLink))
    XCTAssertEqual(
      profile.linkURL,
      link,
      "failed to parse user link"
    )
  }

  func validateCommonLoginParameters(
    _ parameters: [String: String],
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    XCTAssertEqual(
      parameters["client_id"],
      appID,
      file: file,
      line: line
    )
    XCTAssertEqual(
      parameters["display"],
      "touch",
      file: file,
      line: line
    )
    XCTAssertEqual(
      parameters["sdk"],
      "ios",
      file: file,
      line: line
    )
    XCTAssertEqual(
      parameters["return_scopes"],
      "true",
      file: file,
      line: line
    )
    XCTAssertEqual(
      parameters["fbapp_pres"],
      "0",
      file: file,
      line: line
    )
    XCTAssertEqual(
      parameters["ies"],
      settings.isAutoLogAppEventsEnabled ? "1" : "0",
      file: file,
      line: line
    )
    XCTAssertNotNil(
      parameters["e2e"],
      file: file,
      line: line
    )

    let stateJsonString = try XCTUnwrap(parameters["state"], file: file, line: line)
    let state = try BasicUtility.object(forJSONString: stateJsonString) as? [String: Any]
    XCTAssertNotNil(state?["challenge"], file: file, line: line)
    XCTAssertNotNil(state?["0_auth_logger_id"], file: file, line: line)

    let cbt = try XCTUnwrap(parameters["cbt"], file: file, line: line)
    let cbtDouble = try XCTUnwrap(Double(cbt), file: file, line: line)
    let currentMilliseconds = 1000 * Date().timeIntervalSince1970
    XCTAssertEqual(cbtDouble, currentMilliseconds, accuracy: 500, file: file, line: line)
    XCTAssertEqual(
      parameters["redirect_uri"],
      sampleURL.absoluteString,
      file: file,
      line: line
    )
  }
}
