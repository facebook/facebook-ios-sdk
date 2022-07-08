/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import TestTools
import XCTest

final class GameRequestURLProviderTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var internalUtility: TestTools.TestInternalUtility!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    internalUtility = .init()

    GameRequestURLProvider.setDependencies(
      .init(
        accessTokenWallet: TestAccessTokenWallet.self,
        authenticationTokenWallet: TestAuthenticationTokenWallet.self,
        appAvailabilityChecker: internalUtility
      )
    )
  }

  override func tearDown() {
    internalUtility = nil
    TestAccessTokenWallet.reset()
    TestAuthenticationTokenWallet.reset()
    GameRequestURLProvider.resetDependencies()

    super.tearDown()
  }

  // MARK: - Dependencies

  func testCustomDependencies() throws {
    let dependencies = try GameRequestURLProvider.getDependencies()

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
      dependencies.appAvailabilityChecker,
      internalUtility,
      .Dependencies.customDependency(for: "app availability checker")
    )
  }

  func testDefaultDependencies() throws {
    GameRequestURLProvider.resetDependencies()
    let dependencies = try GameRequestURLProvider.getDependencies()

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
    XCTAssertIdentical(
      dependencies.appAvailabilityChecker,
      InternalUtility.shared,
      .Dependencies.defaultDependency("InternalUtility", for: "app availability checker")
    )
  }

  // MARK: - Action Type Name

  func testActionTypeName() {
    [
      (GameRequestActionType.askFor, "askfor"),
      (.invite, "invite"),
      (.send, "send"),
      (.turn, "turn"),
    ]
      .forEach { pair in
        XCTAssertEqual(
          GameRequestURLProvider.actionTypeName(for: pair.0),
          pair.1,
          "The name of the action type: \(pair.0) should be: \(pair.1)"
        )
      }
    XCTAssertNil(
      GameRequestURLProvider.actionTypeName(for: .none),
      "The `none` action type should not have a name"
    )
  }

  func testSimpleFilterNames() {
    [
      (GameRequestFilter.appUsers, "app_users"),
      (.appNonUsers, "app_non_users"),
    ]
      .forEach { pair in
        XCTAssertEqual(
          GameRequestURLProvider.filtersName(for: pair.0),
          pair.1,
          "The name of the filter: \(pair.0) should be: \(pair.1)"
        )
      }
  }

  func testFilterNameForEverybodyWithoutGamingDomain() {
    TestAuthenticationTokenWallet.current = SampleAuthenticationToken.validToken(withGraphDomain: "facebook")

    XCTAssertNil(
      GameRequestURLProvider.filtersName(for: .everybody),
      "Should not have a filter name for `everybody` when the graph domain is not gaming"
    )
  }

  func testFilterNameForEverybodyWithGamingDomainWithoutFacebookAppInstalled() {
    TestAuthenticationTokenWallet.current = SampleAuthenticationToken.validToken(withGraphDomain: "gaming")
    internalUtility.isFacebookAppInstalled = false

    XCTAssertNil(
      GameRequestURLProvider.filtersName(for: .everybody),
      "Should not have a filter name for `everybody` when the facebook app is not installed"
    )
  }

  func testFilterNameForEverybodyWithGamingDomainWithFacebookAppInstalled() {
    TestAuthenticationTokenWallet.current = SampleAuthenticationToken.validToken(withGraphDomain: "gaming")
    internalUtility.isFacebookAppInstalled = true

    XCTAssertEqual(
      GameRequestURLProvider.filtersName(for: .everybody),
      "everybody",
      "Should have a filter name for `everybody` when the graph domain is gaming and the facebook app is installed"
    )
  }

  func testFilterNameForNoneFilter() {
    XCTAssertNil(GameRequestURLProvider.filtersName(for: .none), "Should not have a filter name for the `none` filter")
  }

  func testCreatingDeepLinkURLWithAccessToken() throws {
    TestAccessTokenWallet.current = SampleAccessTokens.validToken

    let rawQueries: [String: Any] = [
      "foo": "bar",
      "baz": 1,
    ]

    let url = try XCTUnwrap(
      GameRequestURLProvider.createDeepLinkURL(queryDictionary: rawQueries),
      "Should create a valid deep link url"
    )

    XCTAssertEqual(
      url.scheme,
      "https",
      "Should use the expected url scheme"
    )
    XCTAssertEqual(
      url.host,
      "fb.gg",
      "Should use the expected url host"
    )
    XCTAssertEqual(
      url.path,
      "/game_requestui/appID123",
      "The path should include the app ID from the access token"
    )
    XCTAssertEqual(
      url.query,
      "foo=bar",
      "Should omit any query items with non-String values"
    )
  }

  func testCreatingDeepLinkURLWithoutAccessToken() throws {
    let url = try XCTUnwrap(
      GameRequestURLProvider.createDeepLinkURL(queryDictionary: [:]),
      "Should create a valid deep link url"
    )

    XCTAssertEqual(
      url.path,
      "/game_requestui",
      "Should omit the app ID from the path when it is not available"
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  enum Dependencies {
    static func defaultDependency(_ dependency: String, for type: String) -> String {
      "A GameRequestURLProvider type uses \(dependency) as its \(type) dependency by default"
    }

    static func customDependency(for type: String) -> String {
      "A GameRequestURLProvider type uses a custom \(type) dependency when provided"
    }
  }
}
