/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

import FBSDKCoreKit
import FBSDKCoreKit_Basics

final class LoginCompletionTests: XCTestCase {

  enum Keys {
    static let accessToken = "access_token"
    static let dataAccessExpiration = "data_access_expiration_time"
    static let deniedScopes = "denied_scopes"
    static let expires = "expires"
    static let expiresAt = "expires_at"
    static let expiresIn = "expires_in"
    static let grantedScopes = "granted_scopes"
    static let graphDomain = "graph_domain"
    static let idToken = "id_token"
    static let nonce = "nonce"
    static let userID = "user_id"
    static let code = "code"
    static let error = "error"
  }

  enum Values {
    static let appID = "1234567"
    static let idToken = "abc123"
    static let nonce = "some_nonce"
    static let codeVerifier = "some_code_verifier"
    static let redirectURL = "https://www.example.com"
    static let accessToken = "some_token"
  }

  // swiftlint:disable implicitly_unwrapped_optional
  var authenticationTokenFactory: TestAuthenticationTokenFactory!
  var graphRequestFactory: TestGraphRequestFactory!
  var internalUtility: TestInternalUtility!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    LoginURLCompleter.reset()

    authenticationTokenFactory = TestAuthenticationTokenFactory()
    graphRequestFactory = TestGraphRequestFactory()
    internalUtility = TestInternalUtility()

    internalUtility.stubbedAppURL = URL(string: Values.redirectURL)
  }

  override func tearDown() {
    LoginURLCompleter.reset()

    super.tearDown()
  }

  // MARK: Creation

  func testDefaultProfileProvider() {
    XCTAssertTrue(
      LoginURLCompleter.profileFactory is ProfileFactory,
      "Should have the expected concrete profile provider"
    )
  }

  func testSettingProfileProvider() {
    let provider = TestProfileFactory(stubbedProfile: SampleUserProfiles.createValid())
    LoginURLCompleter.profileFactory = provider

    XCTAssertTrue(
      LoginURLCompleter.profileFactory === provider,
      "Should be able to inject a profile provider"
    )
  }

  func testInitWithAccessTokenWithIDToken() {
    let parameters = SampleRawLoginCompletionParameters.withAccessTokenWithIDToken

    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyParameters(actual: completer.parameters, expected: parameters)
  }

  func testInitWithAccessToken() {
    let parameters = SampleRawLoginCompletionParameters.withAccessToken
    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyParameters(actual: completer.parameters, expected: parameters)
  }

  func testInitWithNonce() {
    let parameters = SampleRawLoginCompletionParameters.withNonce
    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyParameters(actual: completer.parameters, expected: parameters)
  }

  func testInitWithCode() {
    let parameters = SampleRawLoginCompletionParameters.withCode
    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyParameters(actual: completer.parameters, expected: parameters)
  }

  func testInitWithIDToken() {
    let parameters = SampleRawLoginCompletionParameters.withIDToken
    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyParameters(actual: completer.parameters, expected: parameters)
  }

  func testInitWithStringExpirations() {
    let parameters = SampleRawLoginCompletionParameters.withStringExpirations
    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyParameters(actual: completer.parameters, expected: parameters)
  }

  func testInitWithoutAccessTokenWithoutIDTokenWithoutCode() {
    let parameters = SampleRawLoginCompletionParameters.withoutAccessTokenWithoutIDTokenWithoutCode
    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyEmptyParameters(completer.parameters)
  }

  func testInitWithEmptyStrings() {
    let parameters = SampleRawLoginCompletionParameters.withEmptyStrings
    let completer = createLoginCompleter(parameters: parameters, appID: Values.appID)

    verifyEmptyParameters(completer.parameters)
  }

  func testInitWithEmptyParameters() {
    let completer = createLoginCompleter(parameters: [:], appID: Values.appID)

    verifyEmptyParameters(completer.parameters)
  }

  func testInitWithError() {
    let parameters = SampleRawLoginCompletionParameters.withError
    let completer = createLoginCompleter(
      parameters: parameters,
      appID: Values.appID
    )

    XCTAssertNotNil(completer.parameters.error)
  }

  func testInitWithFuzzyParameters() {
    (0 ..< 100).forEach { _ in
      let parameters = SampleRawLoginCompletionParameters.defaultParameters
      if let fuzzyParameters = Fuzzer.randomize(json: parameters) as? [String: Any] {
        _ = createLoginCompleter(parameters: fuzzyParameters, appID: Values.appID)
      }
    }
  }

  // MARK: Completion

  func testCompleteWithNonceGraphRequestCreation() throws {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withNonce,
      appID: Values.appID
    )
    let handler: LoginCompletionParametersBlock = { _ in }

    completer.completeLogin(handler: handler)

    XCTAssertNil(completer.parameters.error)
    XCTAssertNil(authenticationTokenFactory.capturedTokenString)
    let capturedRequest = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
    XCTAssertEqual(
      capturedRequest.graphPath,
      "oauth/access_token",
      "Should create a graph request with the expected graph path"
    )
    XCTAssertEqual(
      capturedRequest.parameters["grant_type"] as? String,
      "fb_exchange_nonce",
      "Should create a graph request with the expected grant type parameter"
    )
    XCTAssertEqual(
      capturedRequest.parameters["fb_exchange_nonce"] as? String,
      completer.parameters.nonceString,
      "Should create a graph request with the expected nonce parameter"
    )
    XCTAssertEqual(
      capturedRequest.parameters["client_id"] as? String,
      Values.appID,
      "Should create a graph request with the expected app id parameter"
    )
    XCTAssertEqual(
      capturedRequest.parameters["fields"] as? String,
      "",
      "Should create a graph request with the expected fields parameter"
    )
    XCTAssertEqual(
      capturedRequest.flags,
      [.doNotInvalidateTokenOnError, .disableErrorRecovery],
      "The graph request should not invalidate the token on error or disable error recovery"
    )
  }

  func testNonceExchangeCompletionWithError() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withNonce,
      appID: Values.appID
    )

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    completer.completeLogin { parameters in
      capturedParameters = parameters
      completionWasInvoked = true
    }

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, SampleError())

    XCTAssertEqual(
      completer.parameters,
      capturedParameters,
      "Should call the completion with the provided parameters"
    )
    XCTAssertTrue(
      completer.parameters.error is SampleError,
      "Should pass through the error from the graph request"
    )

    XCTAssertTrue(completionWasInvoked)
  }

  func testNonceExchangeCompletionWithAccessTokenString() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withNonce,
      appID: Values.appID
    )
    let stubbedResult = [Keys.accessToken: name]

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    completer.completeLogin { parameters in
      capturedParameters = parameters
      completionWasInvoked = true
    }

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, stubbedResult, nil)

    XCTAssertEqual(
      completer.parameters,
      capturedParameters,
      "Should call the completion with the provided parameters"
    )
    XCTAssertEqual(
      completer.parameters.accessTokenString,
      name,
      "Should set the access token string from the graph request's result"
    )
    XCTAssertTrue(completionWasInvoked)
  }

  func testNonceExchangeCompletionWithAccessTokenStringAndAuthenticationTokenString() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withNonce,
      appID: Values.appID
    )
    let nonce = Values.nonce
    let stubbedResult = [
      Keys.accessToken: name,
      Keys.idToken: Values.idToken,
    ]

    completer.completeLogin(
      handler: { _ in },
      nonce: nonce,
      codeVerifier: Values.codeVerifier
    )

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, stubbedResult, nil)

    XCTAssertEqual(
      completer.parameters.accessTokenString,
      name,
      "Should set the access token string from the graph request's result"
    )
    XCTAssertEqual(
      completer.parameters.authenticationTokenString,
      Values.idToken,
      "Should set the authentication token string from the graph request's result"
    )
    XCTAssertEqual(
      authenticationTokenFactory.capturedTokenString,
      Values.idToken,
      "Should call AuthenticationTokenFactory with the expected token string"
    )
    XCTAssertEqual(
      authenticationTokenFactory.capturedNonce,
      nonce,
      "Should call AuthenticationTokenFactory with the expected nonce"
    )
  }

  func testNonceExchangeWithRandomResults() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withNonce,
      appID: Values.appID
    )

    let stubbedResult: [String: Any] = [
      Keys.accessToken: name,
      "expires_in": "10000",
      "data_access_expiration_time": 1,
    ]

    var completionWasInvoked = false
    completer.completeLogin { _ in
      // Basically just making sure that nothing crashes here when we feed it garbage results
      completionWasInvoked = true
    }

    (0 ..< 100).forEach { _ in
      let mangledResult = stubbedResult
      let parameters = Fuzzer.randomize(json: mangledResult)

      graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, parameters, nil)

      XCTAssertTrue(completionWasInvoked)
      completionWasInvoked = false
    }
  }

  func testCompleteWithCodeGraphRequestCreation() throws {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withCode,
      appID: Values.appID
    )
    let handler: LoginCompletionParametersBlock = { _ in }

    completer.completeLogin(
      handler: handler,
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    XCTAssertNil(completer.parameters.error)
    XCTAssertNil(authenticationTokenFactory.capturedTokenString)
    let capturedRequest = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
    XCTAssertEqual(
      capturedRequest.graphPath,
      "oauth/access_token",
      "Should create a graph request with the expected graph path"
    )
    XCTAssertEqual(
      capturedRequest.parameters["client_id"] as? String,
      Values.appID,
      "Should create a graph request with the expected app ID"
    )
    XCTAssertEqual(
      capturedRequest.parameters["redirect_uri"] as? String,
      Values.redirectURL,
      "Should create a graph request with the expected redirect URL"
    )
    XCTAssertEqual(
      capturedRequest.parameters["code_verifier"] as? String,
      Values.codeVerifier,
      "Should create a graph request with the expected code verifier parameter"
    )
    XCTAssertEqual(
      capturedRequest.parameters[Keys.code] as? String,
      SampleRawLoginCompletionParameters.withCode[Keys.code] as? String,
      "Should create a graph request with the expected code parameter"
    )
    XCTAssertEqual(
      capturedRequest.flags,
      [.doNotInvalidateTokenOnError, .disableErrorRecovery],
      "The graph request should not invalidate the token on error or disable error recovery"
    )
  }

  func testCodeExchangeCompletionWithGraphError() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withCode,
      appID: Values.appID
    )

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    let handler: LoginCompletionParametersBlock = { parameters in
      capturedParameters = parameters
      completionWasInvoked = true
    }

    completer.completeLogin(
      handler: handler,
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, SampleError())

    XCTAssertEqual(
      completer.parameters,
      capturedParameters,
      "Should call the completion with the provided parameters"
    )
    XCTAssertTrue(
      completer.parameters.error is SampleError,
      "Should pass through the error from the graph request"
    )

    XCTAssertTrue(completionWasInvoked)
  }

  func testCodeExchangeCompletionWithError() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withCode,
      appID: Values.appID
    )
    let stubbedResult = [Keys.error: name]

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    let handler: LoginCompletionParametersBlock = { parameters in
      capturedParameters = parameters
      completionWasInvoked = true
    }

    completer.completeLogin(
      handler: handler,
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, stubbedResult, nil)

    XCTAssertEqual(
      completer.parameters,
      capturedParameters,
      "Should call the completion with the provided parameters"
    )
    XCTAssertNotNil(
      completer.parameters.error,
      "Should set error from the graph request's result"
    )
    XCTAssertTrue(completionWasInvoked)
  }

  func testCodeExchangeCompletionWithAccessTokenString() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withCode,
      appID: Values.appID
    )
    let stubbedResult = [Keys.accessToken: name]

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    let handler: LoginCompletionParametersBlock = { parameters in
      capturedParameters = parameters
      completionWasInvoked = true
    }

    completer.completeLogin(
      handler: handler,
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, stubbedResult, nil)

    XCTAssertEqual(
      completer.parameters,
      capturedParameters,
      "Should call the completion with the provided parameters"
    )
    XCTAssertEqual(
      completer.parameters.accessTokenString,
      name,
      "Should set the access token string from the graph request's result"
    )
    XCTAssertTrue(completionWasInvoked)
  }

  func testCodeExchangeCompletionWithAccessTokenStringAndAuthenticationTokenString() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withCode,
      appID: Values.appID
    )
    let stubbedResult = [
      Keys.accessToken: Values.accessToken,
      Keys.idToken: Values.idToken,
    ]

    completer.completeLogin(
      handler: { _ in },
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, stubbedResult, nil)

    XCTAssertEqual(
      completer.parameters.accessTokenString,
      Values.accessToken,
      "Should set the access token string from the graph request's result"
    )
    XCTAssertEqual(
      completer.parameters.authenticationTokenString,
      Values.idToken,
      "Should set the authentication token string from the graph request's result"
    )
    XCTAssertEqual(
      authenticationTokenFactory.capturedTokenString,
      Values.idToken,
      "Should call AuthenticationTokenFactory with the expected token string"
    )
    XCTAssertEqual(
      authenticationTokenFactory.capturedNonce,
      Values.nonce,
      "Should call AuthenticationTokenFactory with the expected nonce"
    )
  }

  func testCodeExchangeWithRandomResults() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withCode,
      appID: Values.appID
    )

    let stubbedResult: [String: Any] = [
      Keys.accessToken: Values.accessToken,
      "expires_in": "10000",
      "data_access_expiration_time": 1,
    ]

    var completionWasInvoked = false
    completer.completeLogin(
      handler: { _ in
        // Basically just making sure that nothing crashes here when we feed it garbage results
        completionWasInvoked = true
      },
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    (0 ..< 100).forEach { _ in
      let mangledResult = stubbedResult
      let parameters = Fuzzer.randomize(json: mangledResult)

      graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, parameters, nil)

      XCTAssertTrue(completionWasInvoked)
      completionWasInvoked = false
    }
  }

  func testCompleteWithAuthenticationTokenWithoutNonce() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withIDToken,
      appID: Values.appID
    )

    completer.completeLogin { _ in }

    XCTAssertNotNil(completer.parameters.error)
    XCTAssertEqual(graphRequestFactory.capturedRequests.count, 0)
    XCTAssertNil(authenticationTokenFactory.capturedTokenString)
  }

  func testCompleteWithAuthenticationTokenWithNonce() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withIDToken,
      appID: Values.appID
    )

    let nonce = Values.nonce

    completer.completeLogin(
      handler: { _ in },
      nonce: nonce,
      codeVerifier: Values.codeVerifier
    )

    XCTAssertNil(completer.parameters.error)
    XCTAssertEqual(graphRequestFactory.capturedRequests.count, 0)
    XCTAssertEqual(
      authenticationTokenFactory.capturedTokenString,
      SampleRawLoginCompletionParameters.withIDToken[Keys.idToken] as? String,
      "Should call AuthenticationTokenFactory with the expected token string"
    )
    XCTAssertEqual(
      authenticationTokenFactory.capturedNonce,
      nonce,
      "Should call AuthenticationTokenFactory with the expected nonce"
    )
  }

  func testAuthenticationTokenCreationCompleteWithEmptyResult() {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withIDToken,
      appID: Values.appID
    )

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    completer.completeLogin { parameters in
      capturedParameters = parameters
      completionWasInvoked = true
    }

    authenticationTokenFactory.capturedCompletion?(nil)

    XCTAssertNotNil(capturedParameters?.error)
    XCTAssertNil(capturedParameters?.authenticationToken)
    XCTAssert(
      completionWasInvoked,
      "Handler should be invoked"
    )
  }

  func testAuthenticationTokenCreationCompleteWithToken() throws {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withIDToken,
      appID: Values.appID
    )
    let nonce = Values.nonce

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    completer.completeLogin(
      handler: { parameters in
        capturedParameters = parameters
        completionWasInvoked = true
      },
      nonce: nonce,
      codeVerifier: Values.codeVerifier
    )

    let tokenString = try XCTUnwrap(SampleRawLoginCompletionParameters.withIDToken[Keys.idToken] as? String)
    let token = AuthenticationToken(
      tokenString: tokenString,
      nonce: nonce
    )

    authenticationTokenFactory.capturedCompletion?(token)

    XCTAssertNil(completer.parameters.error)
    let capturedToken = try XCTUnwrap(capturedParameters?.authenticationToken)
    XCTAssertEqual(
      capturedToken.tokenString,
      SampleRawLoginCompletionParameters.withIDToken[Keys.idToken] as? String
    )
    XCTAssertEqual(capturedToken.nonce, nonce)
    XCTAssert(
      completionWasInvoked,
      "Handler should be invoked"
    )
  }

  func testCompleteWithAccessToken() throws {
    let completer = createLoginCompleter(
      parameters: SampleRawLoginCompletionParameters.withAccessToken,
      appID: Values.appID
    )

    var completionWasInvoked = false
    var capturedParameters: LoginCompletionParameters?
    completer.completeLogin(
      handler: { parameters in
        capturedParameters = parameters
        completionWasInvoked = true
      },
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    let parameters = try XCTUnwrap(capturedParameters)
    verifyParameters(
      actual: parameters,
      expected: SampleRawLoginCompletionParameters.withAccessToken
    )

    XCTAssertTrue(completionWasInvoked, "Handler should be invoked")
    XCTAssertNil(completer.parameters.error)
    XCTAssertEqual(graphRequestFactory.capturedRequests.count, 0)
    XCTAssertNil(authenticationTokenFactory.capturedTokenString)
  }

  func testCompleteWithEmptyParameters() {
    let completer = createLoginCompleter(parameters: [:], appID: Values.appID)

    var completionWasInvoked = false
    completer.completeLogin(
      handler: { _ in
        completionWasInvoked = true
      },
      nonce: Values.nonce,
      codeVerifier: Values.codeVerifier
    )

    XCTAssert(completionWasInvoked, "Handler should be invoked")
    XCTAssertNil(completer.parameters.error)
    XCTAssertEqual(graphRequestFactory.capturedRequests.count, 0)
    XCTAssertNil(authenticationTokenFactory.capturedTokenString)
  }

  // MARK: Profile

  func testCreateProfileWithClaims() throws {
    let factory = TestProfileFactory(stubbedProfile: SampleUserProfiles.createValid())
    LoginURLCompleter.profileFactory = factory

    let claim = try XCTUnwrap(
      AuthenticationTokenClaims(
        jti: "some_jti",
        iss: "some_iss",
        aud: "some_aud",
        nonce: Values.nonce,
        exp: 1234,
        iat: 1234,
        sub: "some_sub",
        name: "some_name",
        givenName: "first",
        middleName: "middle",
        familyName: "last",
        email: "example@example.com",
        picture: "www.facebook.com",
        userFriends: ["123", "456"],
        userBirthday: "01/01/1990",
        userAgeRange: ["min": 21],
        userHometown: ["id": "112724962075996", "name": "Martinez, California"],
        userLocation: ["id": "110843418940484", "name": "Seattle, Washington"],
        userGender: "male",
        userLink: "facebook.com"
      )
    )
    LoginURLCompleter.profile(with: claim)

    XCTAssertEqual(
      factory.capturedUserID,
      claim.sub,
      "Should request a profile with the claims sub as the user identifier"
    )
    XCTAssertEqual(
      factory.capturedName,
      claim.name,
      "Should request a profile using the name from the claims"
    )
    XCTAssertEqual(
      factory.capturedFirstName,
      claim.givenName,
      "Should request a profile using the first name from the claims"
    )
    XCTAssertEqual(
      factory.capturedMiddleName,
      claim.middleName,
      "Should request a profile using the middle name from the claims"
    )
    XCTAssertEqual(
      factory.capturedLastName,
      claim.familyName,
      "Should request a profile using the last name from the claims"
    )
    XCTAssertEqual(
      factory.capturedImageURL?.absoluteString,
      claim.picture,
      "Should request an image URL from the claims"
    )
    XCTAssertEqual(
      factory.capturedEmail,
      claim.email,
      "Should request a profile using the email from the claims"
    )
    XCTAssertEqual(
      factory.capturedFriendIDs,
      claim.userFriends,
      "Should request a profile using the friend identifiers from the claims"
    )
    // @lint-ignore FBOBJCDISCOURAGEDFUNCTION
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy"
    let capturedBirthday = try XCTUnwrap(factory.capturedBirthday)
    XCTAssertEqual(
      formatter.string(from: capturedBirthday),
      claim.userBirthday,
      "Should request a profile using the user birthday from the claims"
    )
    let rawAgeRange = try XCTUnwrap(claim.userAgeRange)
    XCTAssertEqual(
      factory.capturedAgeRange,
      UserAgeRange(from: rawAgeRange),
      "Should request a profile using the user age range from the claims"
    )
    let rawHometownLocation = try XCTUnwrap(claim.userHometown)
    XCTAssertEqual(
      factory.capturedHometown,
      Location(from: rawHometownLocation),
      "Should request a profile using the user hometown from the claims"
    )
    let rawUserLocation = try XCTUnwrap(claim.userLocation)
    XCTAssertEqual(
      factory.capturedLocation,
      Location(from: rawUserLocation),
      "Should request a profile using the user location from the claims"
    )
    XCTAssertEqual(
      factory.capturedGender,
      claim.userGender,
      "Should request a profile using the gender from the claims"
    )
    let rawUserLink = try XCTUnwrap(claim.userLink)
    XCTAssertEqual(
      factory.capturedLinkURL,
      URL(string: rawUserLink),
      "Should request a profile using the link from the claims"
    )
    XCTAssertTrue(
      factory.capturedIsLimited,
      "Should request a profile with limited information"
    )
  }

  // MARK: - Helpers

  func createLoginCompleter(parameters: [String: Any], appID: String) -> LoginURLCompleter {
    LoginURLCompleter(
      urlParameters: parameters,
      appID: appID,
      authenticationTokenCreator: authenticationTokenFactory,
      graphRequestFactory: graphRequestFactory,
      internalUtility: internalUtility
    )
  }

  func verifyParameters(
    actual: LoginCompletionParameters,
    expected: [String: Any],
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    XCTAssertEqual(
      actual.accessTokenString,
      expected[Keys.accessToken] as? String,
      file: file,
      line: line
    )
    XCTAssertEqual(
      actual.authenticationTokenString,
      expected[Keys.idToken] as? String,
      file: file,
      line: line
    )
    XCTAssertEqual(
      actual.appID,
      Values.appID,
      file: file,
      line: line
    )
    XCTAssertEqual(
      actual.challenge,
      SampleRawLoginCompletionParameters.fakeChallenge,
      file: file,
      line: line
    )
    if let rawGrantedPermissions = expected[Keys.grantedScopes] as? String {
      let grantedPermissions = Set(
        rawGrantedPermissions
          .split(separator: ",")
          .compactMap { FBPermission(string: String($0)) }
      )

      XCTAssertEqual(
        actual.permissions,
        grantedPermissions,
        file: file,
        line: line
      )
    }
    if let rawDeclinedPermissions = expected[Keys.deniedScopes] as? String {
      let declinedPermissions = Set(
        rawDeclinedPermissions
          .split(separator: ",")
          .compactMap { FBPermission(string: String($0)) }
      )

      XCTAssertEqual(
        actual.declinedPermissions,
        declinedPermissions,
        file: file,
        line: line
      )
    }
    XCTAssertEqual(
      actual.userID,
      expected[Keys.userID] as? String,
      file: file,
      line: line
    )
    XCTAssertEqual(
      actual.graphDomain,
      expected[Keys.graphDomain] as? String,
      file: file,
      line: line
    )

    if let expectedExpires = expected[Keys.expires] as? Double,
       let expires = actual.expirationDate?.timeIntervalSince1970 {
      XCTAssertEqual(
        expires,
        expectedExpires,
        accuracy: 100,
        file: file,
        line: line
      )
    }
    if let expectedExpiresAt = expected[Keys.expiresAt] as? Double,
       let expiresAt = actual.expirationDate?.timeIntervalSince1970 {
      XCTAssertEqual(
        expiresAt,
        expectedExpiresAt,
        accuracy: 100,
        file: file,
        line: line
      )
    }
    if let expectedExpiresIn = expected[Keys.expiresIn] as? Double,
       let expiresIn = actual.expirationDate?.timeIntervalSinceNow {
      XCTAssertEqual(
        expiresIn,
        expectedExpiresIn,
        accuracy: 100,
        file: file,
        line: line
      )
    }
    if let expectedDataAccessExpiration = expected[Keys.dataAccessExpiration] as? TimeInterval,
       let dataExpiration = actual.dataAccessExpirationDate?.timeIntervalSince1970 {
      XCTAssertEqual(
        dataExpiration,
        expectedDataAccessExpiration,
        accuracy: 100,
        file: file,
        line: line
      )
    }

    XCTAssertEqual(
      actual.nonceString,
      expected[Keys.nonce] as? String,
      file: file,
      line: line
    )
    XCTAssertNil(actual.error, file: file, line: line)
  }

  func verifyEmptyParameters(
    _ parameters: LoginCompletionParameters,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    XCTAssertNil(parameters.accessTokenString, file: file, line: line)
    XCTAssertNil(parameters.authenticationTokenString, file: file, line: line)
    XCTAssertNil(parameters.appID, file: file, line: line)
    XCTAssertNil(parameters.challenge, file: file, line: line)
    XCTAssertNil(parameters.permissions, file: file, line: line)
    XCTAssertNil(parameters.declinedPermissions, file: file, line: line)
    XCTAssertNil(parameters.userID, file: file, line: line)
    XCTAssertNil(parameters.graphDomain, file: file, line: line)
    XCTAssertNil(parameters.expirationDate, file: file, line: line)
    XCTAssertNil(parameters.dataAccessExpirationDate, file: file, line: line)
    XCTAssertNil(parameters.nonceString, file: file, line: line)
    XCTAssertNil(parameters.error, file: file, line: line)
  }
}
