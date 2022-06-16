/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import FBSDKCoreKit_Basics
import TestTools
import XCTest

final class LoginManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var claims: [String: Any]!
  var internalUtility: TestInternalUtility!
  var loginManager: LoginManager!
  var keychainStoreFactory: TestKeychainStoreFactory!
  var keychainStore: TestKeychainStore!
  var urlOpener: TestURLOpener!
  var settings: TestSettings!
  var loginCompleter: TestLoginCompleter!
  var loginCompleterFactory: TestLoginCompleterFactory!
  var testUser: Profile!
  var graphRequestFactory: TestGraphRequestFactory!
  var errorFactory: TestErrorFactory!
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
    urlOpener = TestURLOpener()
    settings = TestSettings()
    settings.appID = appID
    loginCompleter = TestLoginCompleter()
    loginCompleterFactory = TestLoginCompleterFactory(stubbedLoginCompleter: loginCompleter)
    graphRequestFactory = TestGraphRequestFactory()
    errorFactory = TestErrorFactory()

    loginManager = LoginManager()
    loginManager.setDependencies(
      .init(
        accessTokenWallet: TestAccessTokenWallet.self,
        authenticationTokenWallet: TestAuthenticationTokenWallet.self,
        errorFactory: errorFactory,
        graphRequestFactory: graphRequestFactory,
        internalUtility: internalUtility,
        keychainStore: keychainStore,
        loginCompleterFactory: loginCompleterFactory,
        profileProvider: TestProfileProvider.self,
        settings: settings,
        urlOpener: urlOpener
      )
    )
    testUser = createProfile()
    TestProfileProvider.current = testUser

    AuthenticationToken.current = nil
    TestAccessTokenWallet.current = nil

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
          "name": "Martinez, California",
        ]
      ),
      location: Location(
        from: [
          "id": "110843418940484",
          "name": "Seattle, Washington",
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
    urlOpener = nil
    settings = nil
    loginCompleter = nil
    loginCompleterFactory = nil
    errorFactory = nil

    resetClassDependencies()

    super.tearDown()
  }

  func resetClassDependencies() {
    Profile.reset()
    AccessToken.resetClassDependencies()
    AccessToken.resetCurrentAccessTokenCache()
    AuthenticationToken.resetCurrentAuthenticationTokenCache()
    TestAccessTokenWallet.reset()
    TestProfileProvider.reset()
  }

  func testCustomDependencies() throws {
    let dependencies = try loginManager.getDependencies()

    XCTAssertIdentical(
      dependencies.accessTokenWallet,
      TestAccessTokenWallet.self,
      .Dependencies.customDependency(for: "access token wallet")
    )
    XCTAssertIdentical(
      dependencies.authenticationTokenWallet,
      TestAuthenticationTokenWallet.self,
      .Dependencies.customDependency(for: "authentication token wallet")
    )
    XCTAssertIdentical(
      dependencies.errorFactory,
      errorFactory,
      .Dependencies.customDependency(for: "error factory")
    )
    XCTAssertIdentical(
      dependencies.graphRequestFactory,
      graphRequestFactory,
      .Dependencies.customDependency(for: "graph request factory")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      internalUtility,
      .Dependencies.customDependency(for: "internal utility")
    )
    XCTAssertIdentical(
      dependencies.keychainStore,
      keychainStore,
      .Dependencies.customDependency(for: "keychain store")
    )
    XCTAssertIdentical(
      dependencies.loginCompleterFactory as AnyObject,
      loginCompleterFactory,
      .Dependencies.customDependency(for: "login completer factory")
    )
    XCTAssertIdentical(
      dependencies.profileProvider,
      TestProfileProvider.self,
      .Dependencies.customDependency(for: "profile provider")
    )
    XCTAssertIdentical(
      dependencies.settings,
      settings,
      .Dependencies.customDependency(for: "settings")
    )
    XCTAssertIdentical(
      dependencies.urlOpener,
      urlOpener,
      .Dependencies.customDependency(for: "URL opener")
    )
  }

  func testDefaultDependencies() throws {
    loginManager.resetDependencies()
    let dependencies = try loginManager.getDependencies()

    XCTAssertIdentical(
      dependencies.accessTokenWallet,
      AccessToken.self,
      .Dependencies.defaultDependency("AccessToken", for: "access token wallet")
    )
    XCTAssertIdentical(
      dependencies.authenticationTokenWallet,
      AuthenticationToken.self,
      .Dependencies.defaultDependency("AuthenticationToken", for: "authentication token wallet")
    )
    XCTAssertTrue(
      dependencies.errorFactory is ErrorFactory,
      .Dependencies.defaultDependency("a concrete error factory", for: "error factory")
    )
    XCTAssertTrue(
      dependencies.graphRequestFactory is GraphRequestFactory,
      .Dependencies.defaultDependency("a concrete graph request factory", for: "graph request factory")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      InternalUtility.shared,
      .Dependencies.defaultDependency("the shared InternalUtility", for: "internal utility")
    )

    let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
    let keychainStore = dependencies.keychainStore as? KeychainStore
    XCTAssertEqual(
      keychainStore?.service,
      "com.facebook.sdk.loginmanager.\(bundleIdentifier)",
      .Dependencies.defaultDependency("a keychain store with the appropriate service", for: "keychain store")
    )
    XCTAssertNil(
      keychainStore?.accessGroup,
      .Dependencies.defaultDependency("a keychain store without an access group", for: "keychain store")
    )

    XCTAssertTrue(
      dependencies.loginCompleterFactory is _LoginCompleterFactory,
      .Dependencies.defaultDependency("a concrete login completer factory", for: "login completer factory")
    )
    XCTAssertIdentical(
      dependencies.profileProvider,
      Profile.self,
      .Dependencies.defaultDependency("Profile", for: "profile provider")
    )
    XCTAssertIdentical(
      dependencies.settings,
      Settings.shared,
      .Dependencies.defaultDependency("the shared Settings", for: "settings")
    )
    XCTAssertIdentical(
      dependencies.urlOpener,
      BridgeAPI.shared,
      .Dependencies.defaultDependency("the shared BridgeAPI", for: "URL opener")
    )
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
      "ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0", // swiftlint:disable:this line_length
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
  }

  // MARK: Completing Authentication

  func testCompletingAuthenticationWithMixedPermissionsWithExpectedChallenge() throws {
    var capturedResult: LoginManagerLoginResult?
    loginManager.requestedPermissions = [
      // swiftlint:disable force_unwrapping
      FBPermission(string: "email")!,
      FBPermission(string: "user_friends")!,
      // swiftlint:enable force_unwrapping
    ]
    loginManager.handler = IdentifiedLoginResultHandler { result, _ in
      capturedResult = result
    }

    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let parameters = _LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    parameters.userID = "123"

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

    let result = try XCTUnwrap(capturedResult)
    XCTAssertFalse(result.isCancelled)
    let tokenAfterAuth = try XCTUnwrap(TestAccessTokenWallet.current)
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
    TestAccessTokenWallet.current = SampleAccessTokens.validToken

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    let parameters = _LoginCompletionParameters()
    parameters.error = SampleError()

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

    XCTAssertEqual(
      TestAccessTokenWallet.current,
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
    TestAccessTokenWallet.current = SampleAccessTokens.validToken

    _ = loginManager.application(nil, open: url, sourceApplication: "com.apple.mobilesafari", annotation: nil)

    let completerHandler = try XCTUnwrap(loginCompleter.capturedCompletionHandler)

    let parameters = _LoginCompletionParameters()
    parameters.appID = appID
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])
    parameters.declinedPermissions = []
    parameters.accessTokenString = "sometoken"
    completerHandler(parameters)

    let actualToken = try XCTUnwrap(TestAccessTokenWallet.current)
    XCTAssertEqual(actualToken.userID, "user123", "failed to parse userID")
    XCTAssertEqual(actualToken.declinedPermissions, [], "unexpected permissions")
  }

  // verify that recentlyDeclined is a subset of requestedPermissions (i.e., other declined permissions are not in recentlyDeclined)
  func testCompletingAuthenticationWithRecentlyDeclinedPermissions() throws {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }
    // swiftlint:disable:next force_unwrapping
    loginManager.requestedPermissions = [FBPermission(string: "user_friends")!]

    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let parameters = _LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["user_likes", "user_friends"])

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

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
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }
    // swiftlint:disable:next force_unwrapping
    loginManager.requestedPermissions = [FBPermission(string: "user_friends")!]

    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let parameters = _LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["user_likes", "user_friends"])

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

    let result = try XCTUnwrap(capturedResult)
    XCTAssertNil(result.token)
    XCTAssertNil(capturedError)
    XCTAssertNil(keychainStore.keychainDictionary["expected_login_challenge"])
    XCTAssertTrue(keychainStore.wasStringForKeyCalled)
  }

  // verify that a reauth for already granted permissions is not treated as a cancellation.
  func testCompletingReauthenticationSamePermissionsIsNotCancelled() throws {
    let existingToken = SampleAccessTokens.create(withPermissions: ["public_profile", "read_stream"])
    TestAccessTokenWallet.current = existingToken

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }
    loginManager.requestedPermissions = [
      // swiftlint:disable force_unwrapping
      FBPermission(string: "public_profile")!,
      FBPermission(string: "read_stream")!,
      // swiftlint:enable force_unwrapping
    ]

    _ = keychainStore.setString(
      challenge,
      forKey: "expected_login_challenge",
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )

    let parameters = _LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = challenge
    parameters.authenticationTokenString = "sometoken"
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile", "read_stream"])

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

    let capturedRequest = graphRequestFactory.capturedRequests.first
    XCTAssertEqual(
      capturedRequest?.graphPath,
      "me",
      "Should create a graph request with the expected graph path"
    )
    capturedRequest?.capturedCompletionHandler?(nil, ["id": existingToken.userID], nil)

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
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.requestedPermissions = [
      // swiftlint:disable force_unwrapping
      FBPermission(string: "email")!,
      FBPermission(string: "user_friends")!,
      // swiftlint:enable force_unwrapping
    ]

    let parameters = _LoginCompletionParameters()
    parameters.accessTokenString = "accessTokenString"
    parameters.challenge = "someotherchallenge"
    parameters.authenticationTokenString = "sometoken"
    parameters.declinedPermissions = FBPermission.permissions(fromRawPermissions: ["user_likes", "user_friends"])

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

    XCTAssertNotNil(capturedError)
    XCTAssertNil(capturedResult)
  }

  func testCompletingAuthenticationWithNoChallengeAndError() {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.requestedPermissions = [
      // swiftlint:disable force_unwrapping
      FBPermission(string: "email")!,
      FBPermission(string: "user_friends")!,
      // swiftlint:enable force_unwrapping
    ]

    let parameters = _LoginCompletionParameters()
    parameters.error = SampleError()

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

    XCTAssertNil(capturedResult)
    XCTAssertNotNil(capturedError)
  }

  func testOpenURLWithNonFacebookURL() throws {
    let url = try XCTUnwrap(
      URL(string: "test://test?granted_scopes=public_profile&access_token=sometoken&expires_in=5183949")
    )
    loginManager.state = .performingLogin

    XCTAssertFalse(
      loginManager.application(nil, open: url, sourceApplication: "com.apple.mobilesafari", annotation: nil)
    )

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
    let encodedClaims = claimsData.base64EncodedData()
    let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
    let encodedHeader = headerData.base64EncodedData()

    let tokenString = "\(encodedHeader).\(encodedClaims).signature"

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.requestedPermissions = [
      // swiftlint:disable force_unwrapping
      FBPermission(string: "email")!,
      FBPermission(string: "user_friends")!,
      // swiftlint:enable force_unwrapping
    ]

    let parameters = _LoginCompletionParameters()
    parameters.authenticationTokenString = tokenString
    parameters.authenticationToken = AuthenticationToken(tokenString: tokenString, nonce: nonce)
    parameters.challenge = challenge
    parameters.profile = testUser
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

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
    let encodedClaims = claimsData.base64EncodedData()
    let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
    let encodedHeader = headerData.base64EncodedData()

    let tokenString = "\(encodedHeader).\(encodedClaims).signature"

    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }
    loginManager.requestedPermissions = [
      // swiftlint:disable force_unwrapping
      FBPermission(string: "email")!,
      FBPermission(string: "user_friends")!,
      // swiftlint:enable force_unwrapping
    ]

    let parameters = _LoginCompletionParameters()
    parameters.authenticationTokenString = tokenString
    parameters.authenticationToken = AuthenticationToken(tokenString: tokenString, nonce: nonce)
    parameters.challenge = challenge
    parameters.profile = testUser
    parameters.permissions = FBPermission.permissions(fromRawPermissions: ["public_profile"])

    loginManager.completeAuthentication(parameters: parameters, expectChallenge: true)

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

    loginManager.logIn(permissions: ["public_profile"], from: UIViewController()) { _, _ in }

    XCTAssertTrue(
      urlOpener.wasOpenURLWithSVCCalled,
      "openURLWithSafariViewController should be called"
    )
    XCTAssertFalse(
      urlOpener.wasOpenURLWithoutSVCCalled,
      "openURL should not be called"
    )
    XCTAssertTrue(
      loginManager.usedSafariSession,
      "If useSafariViewController is YES, _usedSFAuthSession should be YES and openURLWithSafariViewController should be invoked" // swiftlint:disable:this line_length
    )

    XCTAssertNotNil(urlOpener.viewController)
  }

  func testCallingLoginWithStateChange() {
    internalUtility.isFacebookAppInstalled = false
    loginManager.usedSafariSession = false
    loginManager.state = .start

    var didInvokeCompletionSynchronously = false
    loginManager.logIn(permissions: ["public_profile"], from: UIViewController()) { _, _ in
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
      _LoginManagerLogger(
        loggingToken: "123",
        tracking: .enabled
      )
    )
    loginManager.logger = logger

    internalUtility.stubbedAppURL = sampleURL
    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        configuration: configuration,
        loggingToken: "",
        authenticationMethod: "sfvc_auth"
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
    XCTAssertNotNil(parameters["code_challenge"])
    XCTAssertEqual(parameters["code_challenge_method"], "S256")
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
        configuration: configuration,
        loggingToken: "",
        authenticationMethod: "browser_auth"
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
    XCTAssertNil(parameters["code_challenge"])
    XCTAssertNil(parameters["code_challenge_method"])
  }

  func testLoginParamsWithNilConfiguration() {
    var capturedResult: LoginManagerLoginResult?
    var capturedError: Error?
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    let parameters = loginManager.logInParameters(
      configuration: nil,
      loggingToken: nil,
      authenticationMethod: "sfvc_auth"
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
    loginManager.logger = _LoginManagerLogger(loggingToken: "123", tracking: .enabled)

    internalUtility.stubbedAppURL = sampleURL

    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        configuration: configuration,
        loggingToken: nil,
        authenticationMethod: "sfvc_auth"
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
    loginManager.logger = _LoginManagerLogger(loggingToken: "123", tracking: .enabled)
    internalUtility.stubbedAppURL = sampleURL

    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        configuration: configuration,
        loggingToken: nil,
        authenticationMethod: "sfvc_auth"
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

  func testLoginParamsWithNilDefaultAudienceType() throws {
    let configuration = LoginConfiguration(
      permissions: ["public_profile", "email"],
      tracking: .enabled,
      messengerPageId: nil,
      authType: nil
    )
    internalUtility.stubbedAppURL = sampleURL

    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        configuration: configuration,
        loggingToken: nil,
        authenticationMethod: "sfvc_auth"
      )
    )

    XCTAssertEqual(
      parameters["default_audience"],
      "friends",
      "A login manager uses an audience of 'friends' by default"
    )
  }

  func testLoginParamsWithExplicitlySetDefaultAudienceType() throws {
    let configuration = LoginConfiguration(
      permissions: ["public_profile", "email"],
      tracking: .enabled,
      messengerPageId: nil,
      authType: nil
    )

    internalUtility.stubbedAppURL = sampleURL
    loginManager.defaultAudience = .everyone

    let parameters = try XCTUnwrap(
      loginManager.logInParameters(
        configuration: configuration,
        loggingToken: nil,
        authenticationMethod: "sfvc_auth"
      )
    )

    XCTAssertEqual(
      parameters["default_audience"],
      "everyone",
      "A login manager has the ability to explicitly set the audience"
    )
  }

  // MARK: Logout

  func testLogout() {
    TestAccessTokenWallet.current = SampleAccessTokens.validToken
    TestAuthenticationTokenWallet.current = SampleAuthenticationToken.validToken
    TestProfileProvider.current = testUser

    loginManager.logOut()

    XCTAssertNil(TestAccessTokenWallet.current)
    XCTAssertNil(TestAuthenticationTokenWallet.current)
    XCTAssertNil(TestProfileProvider.current)
  }

  // MARK: Keychain Store

  func testStoreExpectedNonce() {
    loginManager.storeExpectedNonce("some_nonce")
    XCTAssertEqual(keychainStore.string(forKey: "expected_login_nonce"), "some_nonce")

    loginManager.storeExpectedNonce(nil)
    XCTAssertNil(keychainStore.string(forKey: "expected_login_nonce"))
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
    TestAccessTokenWallet.current = SampleAccessTokens.validToken

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

    XCTAssertTrue(graphRequestFactory.capturedRequests.isEmpty)
    XCTAssertFalse(loginManager.state == .idle)
  }

  // MARK: Permissions

  func testRecentlyGrantedPermissionsWithoutPreviouslyGrantedOrRequestedPermissions() throws {
    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    let recentlyGrantedPermissions = loginManager.getRecentlyGrantedPermissions(from: grantedPermissions)
    XCTAssertEqual(recentlyGrantedPermissions, grantedPermissions)
  }

  func testRecentlyGrantedPermissionsWithPreviouslyGrantedPermissions() throws {
    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    TestAccessTokenWallet.current = SampleAccessTokens.validToken

    let recentlyGrantedPermissions = loginManager.getRecentlyGrantedPermissions(from: grantedPermissions)
    XCTAssertEqual(recentlyGrantedPermissions, grantedPermissions)
  }

  func testRecentlyGrantedPermissionsWithRequestedPermissions() throws {
    TestAccessTokenWallet.current = SampleAccessTokens.create(withPermissions: [])

    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    // swiftlint:disable:next force_unwrapping
    loginManager.requestedPermissions = [FBPermission(string: "user_friends")!]

    let recentlyGrantedPermissions = loginManager.getRecentlyGrantedPermissions(from: grantedPermissions)
    XCTAssertEqual(recentlyGrantedPermissions, grantedPermissions)
  }

  func testRecentlyGrantedPermissionsWithPreviouslyGrantedAndRequestedPermissions() throws {
    TestAccessTokenWallet.current = SampleAccessTokens.create(withPermissions: ["email"])

    let grantedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    // swiftlint:disable:next force_unwrapping
    loginManager.requestedPermissions = [FBPermission(string: "user_friends")!]

    let recentlyGrantedPermissions = loginManager.getRecentlyGrantedPermissions(from: grantedPermissions)
    let expectedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["user_friends"])
    )
    XCTAssertEqual(recentlyGrantedPermissions, expectedPermissions)
  }

  func testRecentlyDeclinedPermissionsWithoutRequestedPermissions() throws {
    let declinedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )

    let recentlyDeclinedPermissions = loginManager.getRecentlyDeclinedPermissions(from: declinedPermissions)
    XCTAssertTrue(recentlyDeclinedPermissions.isEmpty)
  }

  func testRecentlyDeclinedPermissionsWithRequestedPermissions() throws {
    let declinedPermissions = try XCTUnwrap(
      FBPermission.permissions(fromRawPermissions: ["email", "user_friends"])
    )
    // swiftlint:disable:next force_unwrapping
    loginManager.requestedPermissions = [FBPermission(string: "user_friends")!]

    let recentlyDeclinedPermissions = loginManager.getRecentlyDeclinedPermissions(from: declinedPermissions)
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

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, loginResult: result)

    let capturedRequest = graphRequestFactory.capturedRequests.first
    XCTAssertEqual(
      capturedRequest?.graphPath,
      "me",
      "Should create a graph request with the expected graph path"
    )
    XCTAssertEqual(
      capturedRequest?.tokenString,
      SampleAccessTokens.validToken.tokenString,
      "Should create a graph request with the expected access token string"
    )
    XCTAssertEqual(
      capturedRequest?.flags,
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
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, loginResult: result)
    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, SampleError())

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
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, loginResult: result)
    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(
      nil, ["id": SampleAccessTokens.validToken.userID], nil
    )

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
    loginManager.handler = IdentifiedLoginResultHandler { result, error in
      capturedResult = result
      capturedError = error
    }

    loginManager.validateReauthentication(accessToken: SampleAccessTokens.validToken, loginResult: result)
    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, ["id": "456"], nil)

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

// MARK: - Assumptions

fileprivate extension String {
  enum Dependencies {
    static func defaultDependency(_ dependency: String, for type: String) -> String {
      "A LoginManager instance uses \(dependency) as its \(type) dependency by default"
    }

    static func customDependency(for type: String) -> String {
      "A LoginManager instance uses a custom \(type) dependency when provided"
    }
  }
}
