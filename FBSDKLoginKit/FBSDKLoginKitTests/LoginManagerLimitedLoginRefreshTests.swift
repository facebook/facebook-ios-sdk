/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import FBSDKLoginKit

import TestTools
import XCTest

final class LoginManagerLimitedLoginRefreshTests: XCTestCase {

  private enum Values {
    static let appID = "1234567"
    static let nonce = "test_nonce"
    // Match SampleUserProfiles.defaultUserID so Profile.current.userID == claims.sub.
    static let userID = "123"
    static let oldTokenString = "old.token.string"
    static let newTokenString = "new.token.string"
    static let thumbprint = "stub_thumbprint"
  }

  // swiftlint:disable implicitly_unwrapped_optional
  private var loginManager: LoginManager!
  private var settings: TestSettings!
  private var authenticationTokenFactory: TestAuthenticationTokenFactory!
  private var profileFactory: TestProfileFactory!
  private var claimsProvider: StubClaimsProvider!
  private var savedExtractor: ((AuthenticationToken) -> String?)!
  private var savedPerformer: LoginManager.DirectRefreshPerformer!
  private var savedIsEnabled: (() -> Bool)!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    guard #available(iOS 13.0, *) else { return }

    // Boot the SDK so Settings.shared and friends don't trip the v9.0 init guard.
    ApplicationDelegate.shared.application(
      UIApplication.shared,
      didFinishLaunchingWithOptions: [:]
    )

    settings = TestSettings()
    settings.appID = Values.appID

    loginManager = LoginManager()
    loginManager.setDependencies(
      .init(
        accessTokenWallet: TestAccessTokenWallet.self,
        authenticationTokenWallet: TestAuthenticationTokenWallet.self,
        errorFactory: TestErrorFactory(),
        graphRequestFactory: TestGraphRequestFactory(),
        internalUtility: TestInternalUtility(),
        keychainStore: TestKeychainStore(),
        loginCompleterFactory: TestLoginCompleterFactory(stubbedLoginCompleter: TestLoginCompleter()),
        profileProvider: TestProfileProvider.self,
        settings: settings,
        urlOpener: TestURLOpener()
      )
    )

    authenticationTokenFactory = TestAuthenticationTokenFactory()
    profileFactory = TestProfileFactory(stubbedProfile: SampleUserProfiles.validLimited)
    claimsProvider = StubClaimsProvider()

    LimitedLoginRefresher.setDependencies(
      .init(
        authenticationTokenCreator: authenticationTokenFactory,
        claimsProvider: claimsProvider,
        internalUtility: TestInternalUtility(),
        profileFactory: profileFactory,
        settings: settings
      )
    )

    AuthenticationToken.current = AuthenticationToken(
      tokenString: Values.oldTokenString,
      nonce: Values.nonce
    )
    Profile.current = SampleUserProfiles.validLimited

    // Reset rate limiter so tests start with a clean slate.
    RefreshRateLimiter.shared.reset()

    savedExtractor = LoginManager.directRefreshCnfJktExtractor
    savedPerformer = LoginManager.directRefreshPerformer
    savedIsEnabled = LoginManager.directRefreshIsEnabled
    // Default: GK is on, token has cnf.jkt, and the network call succeeds.
    LoginManager.directRefreshIsEnabled = { true }
    LoginManager.directRefreshCnfJktExtractor = { _ in Values.thumbprint }
    LoginManager.directRefreshPerformer = { _, _, completion in
      completion(.success(Values.newTokenString))
    }
  }

  override func tearDown() {
    LoginManager.directRefreshCnfJktExtractor = savedExtractor
    LoginManager.directRefreshPerformer = savedPerformer
    LoginManager.directRefreshIsEnabled = savedIsEnabled
    LimitedLoginRefresher.resetDependencies()
    AuthenticationToken.current = nil
    Profile.current = nil
    RefreshRateLimiter.shared.reset()
    loginManager = nil
    settings = nil
    authenticationTokenFactory = nil
    profileFactory = nil
    claimsProvider = nil
    super.tearDown()
  }

  // MARK: - cnf.jkt presence

  func testDirectOnlyWithoutCnfJktReturnsNotDPoPBound() {
    LoginManager.directRefreshCnfJktExtractor = { _ in nil }

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      Self.assertFailure(result, equals: .notDPoPBound)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  func testDirectOnlyWithCnfJktAttemptsDirectRefresh() {
    var didCallPerformer = false
    LoginManager.directRefreshPerformer = { _, _, completion in
      didCallPerformer = true
      // Stop the flow before processRefreshedToken to keep this test focused.
      completion(.failure(.networkError))
    }

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      Self.assertFailure(result, equals: .networkError)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)

    XCTAssertTrue(didCallPerformer, "Direct refresh performer should be invoked when cnf.jkt is present")
  }

  // MARK: - Successful refresh

  func testDirectOnlySuccessUpdatesProfile() {
    claimsProvider.claimsToReturn = makeValidClaims(sub: Values.userID)

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      switch result {
      case .success:
        XCTAssertEqual(Profile.current?.userID, Values.userID)
      case let .failure(error):
        XCTFail("Expected success, got \(error)")
      }
      exp.fulfill()
    }

    // Advance the AuthenticationTokenCreating async completion.
    let token = AuthenticationToken(tokenString: Values.newTokenString, nonce: Values.nonce)
    authenticationTokenFactory.capturedCompletion?(token)

    wait(for: [exp], timeout: 5)
  }

  func testDirectOnlyUserMismatchReturnsUserMismatchAndDoesNotUpdate() {
    claimsProvider.claimsToReturn = makeValidClaims(sub: "different_user")
    let originalProfile = Profile.current

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      Self.assertFailure(result, equals: .userMismatch)
      // Profile should not have been swapped.
      XCTAssertEqual(Profile.current?.userID, originalProfile?.userID)
      exp.fulfill()
    }

    let token = AuthenticationToken(tokenString: Values.newTokenString, nonce: Values.nonce)
    authenticationTokenFactory.capturedCompletion?(token)

    wait(for: [exp], timeout: 5)
  }

  // MARK: - GateKeeper

  func testDirectOnlyWithGKDisabledReturnsFeatureDisabled() {
    LoginManager.directRefreshIsEnabled = { false }

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      Self.assertFailure(result, equals: .featureDisabled)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  func testAutomaticWithGKDisabledReturnsFeatureDisabledWithoutCascading() {
    // Kill switch must short-circuit the cascade — direct returns .featureDisabled
    // and the cascade should surface that without falling back to silent or explicit.
    LoginManager.directRefreshIsEnabled = { false }

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .automatic) { result in
      Self.assertFailure(result, equals: .featureDisabled)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Rate limiter

  func testDirectOnlyWhenRateLimitedReturnsRateLimited() {
    // Drive the rate limiter into the "denied" state by recording an attempt;
    // the next call will be inside the minimum-interval window.
    RefreshRateLimiter.shared.recordAttempt()

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      Self.assertFailure(result, equals: .rateLimited)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Pre-conditions still apply

  func testDirectOnlyWithoutCurrentTokenReturnsNoCurrentToken() {
    AuthenticationToken.current = nil

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      Self.assertFailure(result, equals: .noCurrentToken)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  func testDirectOnlyWithoutLimitedProfileReturnsNotLimitedLogin() {
    // Use a non-limited profile.
    let profile = Profile(
      userID: Values.userID,
      firstName: nil,
      middleName: nil,
      lastName: nil,
      name: nil,
      linkURL: nil,
      refreshDate: Date(),
      imageURL: nil,
      email: nil,
      friendIDs: nil,
      birthday: nil,
      ageRange: nil,
      hometown: nil,
      location: nil,
      gender: nil,
      isLimited: false
    )
    Profile.current = profile

    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .directOnly) { result in
      Self.assertFailure(result, equals: .notLimitedLogin)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Cascade escalation policy

  func testEscalatesToLowerFrictionTierOnAnyNonKillSwitchFailure() {
    // direct / silent show no Facebook UI — worth trying after ANY non-killswitch
    // failure, so the cascade keeps falling forward (this is what was broken: a
    // direct failure must be able to reach silent).
    for nextPath in [RefreshPath.direct, .silent] {
      XCTAssertTrue(LoginManager.shouldEscalate(after: .networkError, to: nextPath))
      XCTAssertTrue(LoginManager.shouldEscalate(after: .timeout, to: nextPath))
      XCTAssertTrue(LoginManager.shouldEscalate(after: .notDPoPBound, to: nextPath))
      XCTAssertTrue(LoginManager.shouldEscalate(after: .invalidResponse, to: nextPath))
      XCTAssertTrue(LoginManager.shouldEscalate(after: .loginRequired, to: nextPath))
    }
  }

  func testEscalatesToExplicitOnlyForInteractiveAuthErrors() {
    // The explicit tier shows interactive UI — only escalate to it when the user
    // genuinely must re-authenticate.
    XCTAssertTrue(LoginManager.shouldEscalate(after: .loginRequired, to: .explicit))
    XCTAssertTrue(LoginManager.shouldEscalate(after: .consentRequired, to: .explicit))
    // Transient / infrastructure errors must NOT pop a login dialog.
    XCTAssertFalse(LoginManager.shouldEscalate(after: .networkError, to: .explicit))
    XCTAssertFalse(LoginManager.shouldEscalate(after: .timeout, to: .explicit))
    XCTAssertFalse(LoginManager.shouldEscalate(after: .rateLimited, to: .explicit))
    XCTAssertFalse(LoginManager.shouldEscalate(after: .notDPoPBound, to: .explicit))
    XCTAssertFalse(LoginManager.shouldEscalate(after: .invalidResponse, to: .explicit))
  }

  func testFeatureDisabledNeverEscalates() {
    // Kill switch is terminal regardless of the next tier.
    for nextPath in [RefreshPath.direct, .silent, .explicit] {
      XCTAssertFalse(LoginManager.shouldEscalate(after: .featureDisabled, to: nextPath))
    }
  }

  // MARK: - Rate limiting is per user-initiated refresh (entry point), not per tier

  func testAutomaticRateLimitIsCheckedOnceAtEntryPoint() {
    // Push the shared limiter into its denied window.
    RefreshRateLimiter.shared.recordAttempt()

    // The entry point must short-circuit with .rateLimited. (Before rate limiting
    // was lifted to the entry, .automatic ran the per-tier limiter inside direct,
    // which surfaced a different, misleading error through the cascade.)
    let exp = expectation(description: "completion")
    loginManager.refreshLimitedLogin(fallbackPolicy: .automatic) { result in
      Self.assertFailure(result, equals: .rateLimited)
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Helpers

  private static func assertFailure(
    _ result: Result<LimitedLoginRefreshResult, LimitedLoginRefreshError>,
    equals expected: LimitedLoginRefreshError,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    switch result {
    case .success:
      XCTFail("Expected failure \(expected), got success", file: file, line: line)
    case let .failure(error):
      XCTAssertEqual(error, expected, file: file, line: line)
    }
  }

  private func makeValidClaims(sub: String) -> AuthenticationTokenClaims {
    AuthenticationTokenClaims(
      jti: "test_jti",
      iss: "https://facebook.com",
      aud: Values.appID,
      nonce: Values.nonce,
      exp: Date().timeIntervalSince1970 + 3600,
      iat: Date().timeIntervalSince1970,
      sub: sub,
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
  }
}
