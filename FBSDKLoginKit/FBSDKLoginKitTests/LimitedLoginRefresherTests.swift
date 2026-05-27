/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

@testable import FBSDKCoreKit
import TestTools
import XCTest

final class LimitedLoginRefresherTests: XCTestCase {

  enum Values {
    static let appID = "1234567"
    static let existingTokenString = "existing.jwt.token"
    static let refreshedTokenString = "refreshed.jwt.token"
    static let nonce = "test_nonce"
    static let existingUserID = "user_123"
    static let mismatchedUserID = "user_456"
  }

  // swiftlint:disable implicitly_unwrapped_optional
  var internalUtility: TestInternalUtility!
  var settings: TestSettings!
  var authenticationTokenFactory: TestAuthenticationTokenFactory!
  var profileFactory: TestProfileFactory!
  var claimsProvider: StubClaimsProvider!
  var refresher: LimitedLoginRefresher!
  // swiftlint:enable implicitly_unwrapped_optional

  var existingToken: AuthenticationToken {
    AuthenticationToken(
      tokenString: Values.existingTokenString,
      nonce: Values.nonce
    )
  }

  override func setUp() {
    super.setUp()

    internalUtility = TestInternalUtility()
    settings = TestSettings()
    settings.appID = Values.appID
    authenticationTokenFactory = TestAuthenticationTokenFactory()
    profileFactory = TestProfileFactory(stubbedProfile: SampleUserProfiles.validLimited)
    claimsProvider = StubClaimsProvider()
    refresher = LimitedLoginRefresher()

    // Stub facebookURL to return a URL built from the captured parameters
    internalUtility.stubbedFacebookURL = URL(string: "https://limited.facebook.com/dialog/authorize")
    internalUtility.stubbedAppURL = URL(string: "fb\(Values.appID)://authorize")

    LimitedLoginRefresher.setDependencies(
      .init(
        authenticationTokenCreator: authenticationTokenFactory,
        claimsProvider: claimsProvider,
        internalUtility: internalUtility,
        profileFactory: profileFactory,
        settings: settings
      )
    )
  }

  override func tearDown() {
    LimitedLoginRefresher.resetDependencies()
    AuthenticationToken.current = nil
    Profile.current = nil
    internalUtility = nil
    settings = nil
    authenticationTokenFactory = nil
    profileFactory = nil
    claimsProvider = nil
    refresher = nil

    super.tearDown()
  }

  // MARK: - D3: Build Refresh URL

  func testRefreshURLContainsPromptNone() throws {
    let url = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    XCTAssertNotNil(url, "Should return a non-nil URL")

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    XCTAssertEqual(
      queryParams["prompt"],
      "none",
      "The refresh URL should contain prompt=none for silent authentication"
    )
  }

  func testRefreshURLContainsIdTokenHint() throws {
    let url = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    XCTAssertNotNil(url, "Should return a non-nil URL")

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    XCTAssertEqual(
      queryParams["id_token_hint"],
      Values.existingTokenString,
      "The refresh URL should contain the existing token string as id_token_hint"
    )
  }

  func testRefreshURLContainsLimitedLoginMarker() throws {
    let url = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    XCTAssertNotNil(url, "Should return a non-nil URL")

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    XCTAssertEqual(
      queryParams["tp"],
      "ios_14_do_not_track",
      "The refresh URL should contain the Limited Login tracking parameter"
    )
  }

  func testRefreshURLPreservesScopes() throws {
    let scopes = ["public_profile", "email", "user_friends"]
    let url = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: scopes
    )

    XCTAssertNotNil(url, "Should return a non-nil URL")

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    let scopeParam = try XCTUnwrap(queryParams["scope"])
    let returnedScopes = Set(scopeParam.split(separator: ",").map(String.init))

    for scope in scopes {
      XCTAssertTrue(
        returnedScopes.contains(scope),
        "The refresh URL scope parameter should contain '\(scope)'"
      )
    }
  }

  func testRefreshURLUsesLimitedHostPrefix() throws {
    let url = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    XCTAssertNotNil(url, "Should return a non-nil URL")

    let hostPrefix = try XCTUnwrap(internalUtility.capturedFacebookURLHostPrefix)
    XCTAssertTrue(
      hostPrefix.hasPrefix("limited."),
      "The refresh URL host prefix should start with 'limited.'"
    )
  }

  func testRefreshURLIncludesOpenIDScope() throws {
    let url = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    XCTAssertNotNil(url, "Should return a non-nil URL")

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    let scopeParam = try XCTUnwrap(queryParams["scope"])
    let returnedScopes = Set(scopeParam.split(separator: ",").map(String.init))

    XCTAssertTrue(
      returnedScopes.contains("openid"),
      "The refresh URL should always include openid in scope even if not explicitly passed"
    )
  }

  func testRefreshURLMatchesSDKParameterPattern() throws {
    let url = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    XCTAssertNotNil(url, "Should return a non-nil URL")

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    XCTAssertEqual(
      queryParams["sdk"],
      "ios",
      "The refresh URL should contain sdk=ios"
    )
    XCTAssertEqual(
      queryParams["display"],
      "touch",
      "The refresh URL should contain display=touch"
    )
  }

  func testRefreshURLIncludesDpopJktWhenProviderReturnsThumbprint() throws {
    LimitedLoginRefresher.dpopJktProvider = { "stub_thumbprint_43_chars__________________________a" }
    defer { LimitedLoginRefresher.dpopJktProvider = LimitedLoginRefresher.defaultDPoPJktProvider }

    _ = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    XCTAssertEqual(
      queryParams["dpop_jkt"],
      "stub_thumbprint_43_chars__________________________a",
      "Silent refresh must send dpop_jkt so the server can re-bind cnf.jkt to the current device key"
    )
  }

  func testRefreshURLOmitsDpopJktWhenProviderReturnsNil() throws {
    // Provider returns nil when the gate is closed or the keypair is unavailable —
    // the request must still go through, just without the re-bind hint.
    LimitedLoginRefresher.dpopJktProvider = { nil }
    defer { LimitedLoginRefresher.dpopJktProvider = LimitedLoginRefresher.defaultDPoPJktProvider }

    _ = refresher.buildRefreshURL(
      existingToken: existingToken,
      nonce: Values.nonce,
      scopes: ["public_profile"]
    )

    let queryParams = try XCTUnwrap(internalUtility.capturedFacebookURLQueryParameters)
    XCTAssertNil(
      queryParams["dpop_jkt"],
      "Absence of dpop_jkt is the signal to the server to keep the existing cnf.jkt carry-forward"
    )
  }

  // MARK: - D4: Parse Refresh Response

  func testParseSuccessResponse() {
    let url = URL(string: "fbtest://authorize#id_token=abc123")!

    let result = refresher.parseRefreshResponse(url)

    switch result {
    case let .success(tokenString):
      XCTAssertEqual(
        tokenString,
        "abc123",
        "Should extract the id_token from the URL fragment"
      )
    case let .failure(error):
      XCTFail("Expected success but got error: \(error)")
    }
  }

  func testParseLoginRequiredError() {
    let url = URL(string: "fbtest://authorize#error=login_required")!

    let result = refresher.parseRefreshResponse(url)

    switch result {
    case .success:
      XCTFail("Expected failure with loginRequired error")
    case let .failure(error):
      XCTAssertEqual(
        error,
        .loginRequired,
        "Should return .loginRequired when the OIDC error is login_required"
      )
    }
  }

  func testParseConsentRequiredError() {
    let url = URL(string: "fbtest://authorize#error=consent_required")!

    let result = refresher.parseRefreshResponse(url)

    switch result {
    case .success:
      XCTFail("Expected failure with consentRequired error")
    case let .failure(error):
      XCTAssertEqual(
        error,
        .consentRequired,
        "Should return .consentRequired when the OIDC error is consent_required"
      )
    }
  }

  func testParseInvalidResponse() {
    let url = URL(string: "fbtest://authorize")!

    let result = refresher.parseRefreshResponse(url)

    switch result {
    case .success:
      XCTFail("Expected failure with invalidResponse error")
    case let .failure(error):
      XCTAssertEqual(
        error,
        .invalidResponse,
        "Should return .invalidResponse when the URL has no fragment"
      )
    }
  }

  // MARK: - D5: Process Refreshed Token (SECURITY)

  func testRefreshSucceedsWhenUserIDMatches() {
    claimsProvider.claimsToReturn = AuthenticationTokenClaims(
      jti: "test_jti",
      iss: "https://facebook.com",
      aud: Values.appID,
      nonce: Values.nonce,
      exp: Date().timeIntervalSince1970 + 3600,
      iat: Date().timeIntervalSince1970,
      sub: Values.existingUserID,
      name: nil,
      givenName: nil,
      middleName: nil,
      familyName: nil,
      email: nil,
      picture: nil,
      userFriends: nil,
      userBirthday: nil,
      userAgeRange: nil,
      userHometown: nil,
      userLocation: nil,
      userGender: nil,
      userLink: nil
    )

    let expectation = expectation(description: "Completion called")

    refresher.processRefreshedToken(
      Values.refreshedTokenString,
      nonce: Values.nonce,
      existingUserID: Values.existingUserID
    ) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Expected success but got error: \(error)")
      }
      expectation.fulfill()
    }

    // Drive the AuthenticationTokenCreating completion to advance processRefreshedToken
    let token = AuthenticationToken(
      tokenString: Values.refreshedTokenString,
      nonce: Values.nonce
    )
    authenticationTokenFactory.capturedCompletion?(token)

    waitForExpectations(timeout: 1)
  }

  func testRefreshFailsWhenUserIDMismatch() {
    claimsProvider.claimsToReturn = AuthenticationTokenClaims(
      jti: "test_jti",
      iss: "https://facebook.com",
      aud: Values.appID,
      nonce: Values.nonce,
      exp: Date().timeIntervalSince1970 + 3600,
      iat: Date().timeIntervalSince1970,
      sub: Values.mismatchedUserID,
      name: nil,
      givenName: nil,
      middleName: nil,
      familyName: nil,
      email: nil,
      picture: nil,
      userFriends: nil,
      userBirthday: nil,
      userAgeRange: nil,
      userHometown: nil,
      userLocation: nil,
      userGender: nil,
      userLink: nil
    )

    let expectation = expectation(description: "Completion called")

    refresher.processRefreshedToken(
      Values.refreshedTokenString,
      nonce: Values.nonce,
      existingUserID: Values.existingUserID
    ) { result in
      switch result {
      case .success:
        XCTFail("Expected failure with userMismatch error")
      case let .failure(error):
        XCTAssertEqual(
          error,
          .userMismatch,
          "Should fail with .userMismatch when the refreshed token's user ID differs from the existing user"
        )
      }
      expectation.fulfill()
    }

    // Drive the AuthenticationTokenCreating completion to advance processRefreshedToken
    let token = AuthenticationToken(
      tokenString: Values.refreshedTokenString,
      nonce: Values.nonce
    )
    authenticationTokenFactory.capturedCompletion?(token)

    waitForExpectations(timeout: 1)
  }

  func testProfileNotUpdatedOnMismatch() {
    let originalProfile = SampleUserProfiles.createValid(userID: Values.existingUserID)
    Profile.current = originalProfile

    let expectation = expectation(description: "Completion called")

    refresher.processRefreshedToken(
      Values.refreshedTokenString,
      nonce: Values.nonce,
      existingUserID: Values.existingUserID
    ) { _ in
      expectation.fulfill()
    }

    // Simulate token creation with mismatched user ID
    let token = AuthenticationToken(
      tokenString: Values.refreshedTokenString,
      nonce: Values.nonce
    )
    authenticationTokenFactory.capturedCompletion?(token)

    waitForExpectations(timeout: 1)

    // On user mismatch, Profile.current should remain unchanged
    XCTAssertEqual(
      Profile.current?.userID,
      Values.existingUserID,
      "Profile.current should NOT be updated when the refreshed token belongs to a different user"
    )
  }

  func testTokenNotUpdatedOnMismatch() {
    let originalToken = AuthenticationToken(
      tokenString: Values.existingTokenString,
      nonce: "original_nonce"
    )
    AuthenticationToken.current = originalToken

    let expectation = expectation(description: "Completion called")

    refresher.processRefreshedToken(
      Values.refreshedTokenString,
      nonce: Values.nonce,
      existingUserID: Values.existingUserID
    ) { _ in
      expectation.fulfill()
    }

    // Simulate token creation with mismatched user ID
    let token = AuthenticationToken(
      tokenString: Values.refreshedTokenString,
      nonce: Values.nonce
    )
    authenticationTokenFactory.capturedCompletion?(token)

    waitForExpectations(timeout: 1)

    // On user mismatch, AuthenticationToken.current should remain unchanged
    XCTAssertEqual(
      AuthenticationToken.current?.tokenString,
      Values.existingTokenString,
      "AuthenticationToken.current should NOT be updated when the refreshed token belongs to a different user"
    )
  }
}

// MARK: - Test Doubles

final class StubClaimsProvider: AuthenticationTokenClaimsProviding {
  var claimsToReturn: AuthenticationTokenClaims?

  func claims(for token: AuthenticationToken) -> AuthenticationTokenClaims? {
    claimsToReturn
  }
}
