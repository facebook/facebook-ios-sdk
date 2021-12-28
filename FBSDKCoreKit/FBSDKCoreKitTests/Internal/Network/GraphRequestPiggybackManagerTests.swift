/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class GraphRequestPiggybackManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var settings: SettingsProtocol!
  var graphRequestFactory: TestGraphRequestFactory!
  var serverConfigurationProvider: TestServerConfigurationProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    resetCaches()

    graphRequestFactory = TestGraphRequestFactory()
    serverConfigurationProvider = TestServerConfigurationProvider(
      configuration: ServerConfigurationFixtures.defaultConfig
    )
    settings = TestSettings()
    settings.appID = "abc123"
    GraphRequestPiggybackManager.configure(
      withTokenWallet: TestAccessTokenWallet.self,
      settings: settings,
      serverConfigurationProvider: serverConfigurationProvider,
      graphRequestFactory: graphRequestFactory
    )
  }

  override func tearDown() {
    super.tearDown()

    resetCaches()
  }

  func resetCaches() {
    TestAccessTokenWallet.reset()
    GraphRequestPiggybackManager.reset()
    Settings.shared.reset()
  }

  // MARK: - Defaults

  func testDefaultTokenWallet() {
    GraphRequestPiggybackManager.reset()
    XCTAssertNil(
      GraphRequestPiggybackManager.tokenWallet,
      "Should not have an access token provider by default"
    )
  }

  func testConfiguringWithTokenWallet() {
    XCTAssertTrue(
      GraphRequestPiggybackManager.tokenWallet === TestAccessTokenWallet.self,
      "Should be configurable with an access token provider"
    )
  }

  func testRefreshThresholdInSeconds() {
    let oneDayInSeconds: Int32 = 24 * 60 * 60
    XCTAssertEqual(
      GraphRequestPiggybackManager.tokenRefreshThresholdInSeconds,
      oneDayInSeconds,
      "There should be a well-known value for the token refresh threshold"
    )
  }

  func testRefreshRetryInSeconds() {
    let oneHourInSeconds: Int32 = 60 * 60
    XCTAssertEqual(
      GraphRequestPiggybackManager.tokenRefreshRetryInSeconds,
      oneHourInSeconds,
      "There should be a well-known value for the token refresh retry threshold"
    )
  }

  // MARK: - Request Eligibility

  func testSafeForAddingWithMatchingGraphVersionWithAttachment() {
    XCTAssertFalse(
      GraphRequestPiggybackManager.isRequestSafe(
        forPiggyback: SampleGraphRequests.withAttachment
      ),
      "A request with an attachment is not considered safe for piggybacking"
    )
  }

  func testSafeForAddingWithMatchingGraphVersionWithoutAttachment() {
    XCTAssertTrue(
      GraphRequestPiggybackManager.isRequestSafe(
        forPiggyback: SampleGraphRequests.valid
      ),
      "A request without an attachment is considered safe for piggybacking"
    )
  }

  func testSafeForAddingWithoutMatchingGraphVersionWithAttachment() {
    XCTAssertFalse(
      GraphRequestPiggybackManager.isRequestSafe(
        forPiggyback: SampleGraphRequests.withOutdatedVersionWithAttachment
      ),
      "A request with an attachment and outdated version is not considered safe for piggybacking"
    )
  }

  func testSafeForAddingWithoutMatchingGraphVersionWithoutAttachment() {
    XCTAssertFalse(
      GraphRequestPiggybackManager.isRequestSafe(
        forPiggyback: SampleGraphRequests.withOutdatedVersion
      ),
      "A request with an outdated version is not considered safe for piggybacking"
    )
  }

  // MARK: - Adding Requests

  func testAddingRequestsWithoutAppID() {
    settings.appID = nil

    GraphRequestPiggybackManager.addPiggybackRequests(SampleGraphRequestConnections.empty)
    XCTAssertFalse(
      TestAccessTokenWallet.wasTokenRead,
      "Adding a request without an app identifier should attempt to refresh the access token"
    )
    XCTAssertFalse(serverConfigurationProvider.requestToLoadConfigurationCallWasCalled)
  }

  func testAddingRequestsWithEmptyAppID() {
    settings.appID = ""

    GraphRequestPiggybackManager.addPiggybackRequests(SampleGraphRequestConnections.empty)
    XCTAssertFalse(
      TestAccessTokenWallet.wasTokenRead,
      "Adding a request with an empty app identifier should attempt to refresh the access token"
    )
    XCTAssertFalse(serverConfigurationProvider.requestToLoadConfigurationCallWasCalled)
  }

  func testAddingRequestsForConnectionWithSafeRequests() {
    settings.appID = "abc123"

    let connection = SampleGraphRequestConnections.with(requests: [SampleGraphRequests.valid])
    TestAccessTokenWallet.currentAccessToken = twoDayOldToken
    GraphRequestPiggybackManager.addPiggybackRequests(connection)

    XCTAssertTrue(
      TestAccessTokenWallet.wasTokenRead,
      "Adding requests with an expired token should attempt to refresh the access token"
    )
    XCTAssertTrue(serverConfigurationProvider.requestToLoadConfigurationCallWasCalled)
  }

  func testAddingRequestsForConnectionWithUnsafeRequests() {
    settings.appID = "abc123"
    let connection = SampleGraphRequestConnections.with(requests: [SampleGraphRequests.withAttachment])

    TestAccessTokenWallet.currentAccessToken = twoDayOldToken
    GraphRequestPiggybackManager.addPiggybackRequests(connection)

    XCTAssertFalse(
      TestAccessTokenWallet.wasTokenRead,
      "Adding a request without an app identifier should attempt to refresh the access token"
    )
    XCTAssertFalse(serverConfigurationProvider.requestToLoadConfigurationCallWasCalled)
  }

  func testAddingRequestsForConnectionWithSafeAndUnsafeRequests() {
    let connection = SampleGraphRequestConnections.with(requests: [
      SampleGraphRequests.valid,
      SampleGraphRequests.withAttachment
    ])
    GraphRequestPiggybackManager.addPiggybackRequests(connection)
    XCTAssertFalse(serverConfigurationProvider.requestToLoadConfigurationCallWasCalled)
  }

  // MARK: - Adding Token Extension Piggyback

  func testAddsTokenExtensionRequest() throws {
    settings.appID = "abc123"
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    let connection = TestGraphRequestConnection()

    GraphRequestPiggybackManager.addRefreshPiggyback(connection, permissionHandler: nil)

    let request = try XCTUnwrap(
      connection.capturedRequests.first,
      "Adding a refresh piggyback to a connection should add a request for refreshing the access token"
    )

    XCTAssertEqual(
      request.graphPath,
      "oauth/access_token",
      "Should add a request with the correct graph path for refreshing a token"
    )
    XCTAssertEqual(
      request.parameters["grant_type"] as? String,
      "fb_extend_sso_token",
      "Should add a request with the correct parameters for refreshing a token"
    )
    XCTAssertEqual(
      request.parameters["fields"] as? String,
      "",
      "Should add a request with the correct parameters for refreshing a token"
    )
    XCTAssertEqual(
      request.parameters["client_id"] as? String,
      SampleAccessTokens.validToken.appID,
      "Should add a request with the correct parameters for refreshing a token"
    )
  }

  func testCompletingTokenExtensionRequestWithDefaultValues() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: nil
    )

    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedTokenString: SampleAccessTokens.validToken.tokenString
    )
  }

  func testCompletingTokenExtensionRequestWithUpdatedEmptyTokenString() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["access_token": ""]
    )

    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedTokenString: ""
    )
  }

  func testCompletingTokenExtensionRequestWithUpdatedWhitespaceOnlyTokenString() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["access_token": "    "]
    )

    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedTokenString: "    "
    )
  }

  func testCompletingTokenExtensionRequestWithInvalidExpirationDate() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["expires_at": "0"]
    )

    try validateRefreshedToken(TestAccessTokenWallet.currentAccessToken)

    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["expires_at": "-1000"]
    )

    try validateRefreshedToken(TestAccessTokenWallet.currentAccessToken)
  }

  func testCompletingTokenExtensionRequestWithUnreasonableValidExpirationDate() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["expires_at": 100]
    )

    let expectedExpirationDate = Date(timeIntervalSince1970: 100)

    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedExpirationDate: expectedExpirationDate
    )
  }

  func testCompletingTokenExtensionRequestWithReasonableValidExpirationDate() throws {
    let oneWeek: TimeInterval = 60 * 60 * 24 * 7
    let oneWeekFromNow = Date(timeIntervalSinceNow: oneWeek)

    // This is an acceptable value but really should not be.
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["expires_at": oneWeekFromNow.timeIntervalSince1970]
    )

    let expectedExpirationDate = Date(timeIntervalSince1970: oneWeekFromNow.timeIntervalSince1970)

    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedExpirationDate: expectedExpirationDate
    )
  }

  func testCompletingTokenExtensionRequestWithInvalidDataExpirationDate() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["data_access_expiration_time": "0"]
    )

    try validateRefreshedToken(TestAccessTokenWallet.currentAccessToken)

    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["data_access_expiration_time": "-1000"]
    )

    try validateRefreshedToken(TestAccessTokenWallet.currentAccessToken)
  }

  func testCompletingTokenExtensionRequestWithUnreasonableValidDataExpirationDate() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["data_access_expiration_time": 100]
    )

    let expectedExpirationDate = Date(timeIntervalSince1970: 100)

    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedDataExpirationDate: expectedExpirationDate
    )
  }

  func testCompletingTokenExtensionRequestWithReasonableValidDataExpirationDate() throws {
    let oneWeekInSeconds: TimeInterval = 60 * 60 * 24 * 7
    let oneWeekFromNow = Date(timeIntervalSinceNow: oneWeekInSeconds)
    // This is an acceptable value but really should not be.
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["data_access_expiration_time": oneWeekFromNow.timeIntervalSince1970]
    )

    let expectedExpirationDate = Date(timeIntervalSince1970: oneWeekFromNow.timeIntervalSince1970)

    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedDataExpirationDate: expectedExpirationDate
    )
  }

  func testCompletingTokenExtensionRequestWithUpdatedEmptyGraphDomain() throws {
    completeAccessTokenRefresh(
      token: SampleAccessTokens.validToken,
      results: ["graph_domain": ""]
    )

    try validateRefreshedToken(TestAccessTokenWallet.currentAccessToken)
  }

  func testCompletingTokenExtensionRequestWithFuzzyValues() throws {
    (0 ... 100).forEach { _ in
      completeAccessTokenRefresh(
        token: SampleAccessTokens.validToken,
        results: [
          "access_token": Fuzzer.random,
          "expires_at": Fuzzer.random,
          "data_access_expiration_time": Fuzzer.random,
          "graph_domain": Fuzzer.random
        ]
      )
    }
  }

  // MARK: - Adding Permissions Refresh Piggyback

  func testAddsPermissionsRefreshRequest() {
    settings.appID = "abc123"
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    let connection = TestGraphRequestConnection()

    GraphRequestPiggybackManager.addRefreshPiggyback(connection, permissionHandler: nil)

    let permissionRequest = graphRequestFactory.capturedRequests.last

    XCTAssertEqual(
      permissionRequest?.graphPath,
      "me/permissions",
      "Should add a request with the correct graph path for refreshing permissions"
    )
    let expectedParameters = ["fields": ""]

    XCTAssertEqual(
      permissionRequest?.parameters as? [String: String],
      expectedParameters,
      "Should add a request with the correct parameters for refreshing permissions"
    )
  }

  func testCompletingPermissionsRefreshRequestWithEmptyResults() throws {
    let token = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    completePermissionsRefresh(
      forAccessToken: token,
      results: nil
    )

    // Refreshed token clears permissions when there is no error
    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedPermissions: [],
      expectedDeclinedPermissions: [],
      expectedExpiredPermissions: []
    )
  }

  func testCompletingPermissionsRefreshRequestWithEmptyResultsWithError() throws {
    let token = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    completePermissionsRefresh(
      forAccessToken: token,
      results: nil,
      error: SampleError()
    )

    // Refreshed token uses permissions from current access token when there is an error on permissions refresh
    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedPermissions: token.permissions,
      expectedDeclinedPermissions: token.declinedPermissions,
      expectedExpiredPermissions: token.expiredPermissions
    )
  }

  func testCompletingPermissionsRefreshRequestWithNewGrantedPermissions() throws {
    let token = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    let results = SampleRawRemotePermissionList.with(granted: ["foo"], declined: [], expired: [])

    completePermissionsRefresh(forAccessToken: token, results: results)

    // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedPermissions: ["foo"],
      expectedDeclinedPermissions: [],
      expectedExpiredPermissions: []
    )
  }

  func testCompletingPermissionsRefreshRequestWithNewDeclinedPermissions() throws {
    let token = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    let results = SampleRawRemotePermissionList.with(
      granted: [],
      declined: ["foo"],
      expired: []
    )

    completePermissionsRefresh(
      forAccessToken: token,
      results: results
    )

    // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedPermissions: [],
      expectedDeclinedPermissions: ["foo"],
      expectedExpiredPermissions: []
    )
  }

  func testCompletingPermissionsRefreshRequestWithNewExpiredPermissions() throws {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    let results = SampleRawRemotePermissionList.with(
      granted: [],
      declined: [],
      expired: ["foo"]
    )

    completePermissionsRefresh(
      forAccessToken: SampleAccessTokens.validToken,
      results: results
    )

    // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedPermissions: [],
      expectedDeclinedPermissions: [],
      expectedExpiredPermissions: ["foo"]
    )
  }

  func testCompletingPermissionsRefreshRequestWithNewPermissions() throws {
    let token = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    let results = SampleRawRemotePermissionList.with(
      granted: ["foo"],
      declined: ["bar"],
      expired: ["baz"]
    )

    completePermissionsRefresh(
      forAccessToken: token,
      results: results
    )

    // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
    try validateRefreshedToken(
      TestAccessTokenWallet.currentAccessToken,
      expectedPermissions: ["foo"],
      expectedDeclinedPermissions: ["bar"],
      expectedExpiredPermissions: ["baz"]
    )
  }

  func testCompletingPermissionsRefreshRequestWithPermissionsHandlerWithoutError() throws {
    let expectation = XCTestExpectation(description: name)
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    let results = SampleRawRemotePermissionList.with(
      granted: ["foo"],
      declined: ["bar"],
      expired: ["baz"]
    )

    var capturedResult: [String: Any]?
    var capturedError: Error?
    completePermissionsRefresh(
      forAccessToken: SampleAccessTokens.validToken,
      results: results
    ) { _, result, error in
      capturedResult = result as? [String: Any]
      capturedError = error
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)

    XCTAssertEqual(
      capturedResult as NSDictionary?,
      results as NSDictionary,
      "Should pass the raw results to the provided permissions handler"
    )
    XCTAssertNil(
      capturedError,
      "Should invoke the permissions handler regardless of error state"
    )
  }

  func testCompletingPermissionsRefreshRequestWithPermissionsHandlerWithError() throws {
    let expectation = XCTestExpectation(description: name)
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.create(
      withPermissions: ["email"],
      declinedPermissions: ["publish"],
      expiredPermissions: ["friends"]
    )

    let results = SampleRawRemotePermissionList.with(
      granted: ["foo"],
      declined: ["bar"],
      expired: ["baz"]
    )
    let expectedError = SampleError()

    var capturedResult: [String: Any]?
    var capturedError: Error?
    completePermissionsRefresh(
      forAccessToken: SampleAccessTokens.validToken,
      results: results,
      error: expectedError
    ) { _, result, error in
      capturedResult = result as? [String: Any]
      capturedError = error
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)

    XCTAssertEqual(
      capturedResult as NSDictionary?,
      results as NSDictionary,
      "Should pass the raw results to the provided permissions handler"
    )
    XCTAssertTrue(
      capturedError is SampleError,
      "Should pass the error through to the permissions handler"
    )
  }

  // MARK: - Refreshing if Stale

  func testRefreshIfStaleWithoutAccessToken() {
    // Shouldn't add the refresh if there's no access token
    GraphRequestPiggybackManager.addRefreshPiggybackIfStale(SampleGraphRequestConnections.empty)
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  func testRefreshIfStaleWithAccessTokenWithoutRefreshDate() {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    // Should not add the refresh if the access token is missing a refresh date
    GraphRequestPiggybackManager.addRefreshPiggybackIfStale(SampleGraphRequestConnections.empty)
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  // | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
  // | true                           | true                           | true           |
  func testRefreshIfStaleWithOldRefreshWithOldTokenRefresh() {
    TestAccessTokenWallet.currentAccessToken = twoDayOldToken
    GraphRequestPiggybackManager.lastRefreshTry = Date.distantPast
    GraphRequestPiggybackManager.addRefreshPiggybackIfStale(SampleGraphRequestConnections.empty)

    XCTAssertNotNil(graphRequestFactory.capturedGraphPath)
  }

  // | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
  // | true                           | false                          | false          |
  func testRefreshIfStaleWithOldLastRefreshWithRecentTokenRefresh() {
    GraphRequestPiggybackManager.lastRefreshTry = Date.distantPast

    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    GraphRequestPiggybackManager.addRefreshPiggybackIfStale(SampleGraphRequestConnections.empty)
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  // | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
  // | false                          | false                          | false          |
  func testRefreshIfStaleWithRecentLastRefreshWithRecentTokenRefresh() {
    // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
    GraphRequestPiggybackManager.lastRefreshTry = Date.distantFuture
    GraphRequestPiggybackManager.addRefreshPiggybackIfStale(SampleGraphRequestConnections.empty)
    GraphRequestPiggybackManager.lastRefreshTry = Date.distantFuture
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  // | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
  // | false                          | true                           | false          |
  func testRefreshIfStaleWithRecentLastRefreshOldTokenRefresh() {
    // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
    TestAccessTokenWallet.currentAccessToken = twoDayOldToken
    GraphRequestPiggybackManager.lastRefreshTry = Date.distantFuture
    GraphRequestPiggybackManager.addRefreshPiggybackIfStale(SampleGraphRequestConnections.empty)
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  func testRefreshIfStaleSideEffects() {
    // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
    TestAccessTokenWallet.currentAccessToken = twoDayOldToken
    GraphRequestPiggybackManager.lastRefreshTry = Date.distantPast
    GraphRequestPiggybackManager.addRefreshPiggybackIfStale(SampleGraphRequestConnections.empty)
    XCTAssertNotNil(graphRequestFactory.capturedGraphPath)
  }

  // MARK: - Server Configuration Piggyback

  func testAddingServerConfigurationPiggybackWithoutAppID() {
    let configuration = ServerConfigurationFixtures.config(withDictionary: ["defaults": true])
    serverConfigurationProvider.stubbedServerConfiguration = configuration
    settings.appID = nil

    let connection = TestGraphRequestConnection()
    GraphRequestPiggybackManager.addServerConfigurationPiggyback(connection)

    XCTAssertEqual(
      connection.capturedRequests.count,
      0,
      "Should not add a server configuration request without an app ID"
    )
  }

  func testAddingServerConfigurationPiggybackWithDefaultConfigurationExpiredCache() throws {
    let configuration = ServerConfigurationFixtures.config(
      withDictionary: [
        "defaults": true,
        "timestamp": twoDaysAgo
      ]
    )

    let graphRequest = GraphRequest(graphPath: name)
    serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest
    serverConfigurationProvider.stubbedServerConfiguration = configuration

    settings.appID = configuration.appID

    let connection = TestGraphRequestConnection()
    GraphRequestPiggybackManager.addServerConfigurationPiggyback(connection)
    let request = try XCTUnwrap(connection.capturedRequests.first)
    let expectedServerConfigurationRequest = try XCTUnwrap(
      serverConfigurationProvider.request(toLoadServerConfiguration: "")
    )

    try validateServerConfigurationRequestsEqual(request, expectedServerConfigurationRequest)
  }

  func testAddingServerConfigurationPiggybackWithDefaultConfigurationNonExpiredCache() {
    let configuration = ServerConfigurationFixtures.config(
      withDictionary: [
        "defaults": true,
        "timestamp": Date()
      ]
    )
    let graphRequest = GraphRequest(graphPath: name)
    serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest
    serverConfigurationProvider.stubbedServerConfiguration = configuration

    let connection = TestGraphRequestConnection()
    GraphRequestPiggybackManager.addServerConfigurationPiggyback(connection)

    XCTAssertEqual(
      connection.capturedRequests.count,
      1,
      "Should add a server configuration request for a default config with a non-expired cache"
    )
  }

  func testAddingServerConfigurationPiggybackWithCustomConfigurationExpiredCache() {
    let configuration = ServerConfigurationFixtures.config(
      withDictionary: [
        "defaults": true,
        "timestamp": twoDaysAgo
      ]
    )
    let graphRequest = GraphRequest(graphPath: name)
    serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest
    serverConfigurationProvider.stubbedServerConfiguration = configuration

    let connection = TestGraphRequestConnection()
    GraphRequestPiggybackManager.addServerConfigurationPiggyback(connection)

    XCTAssertEqual(
      connection.capturedRequests.count,
      1,
      "Should add a server configuration request for a default config with an expired cached"
    )
  }

  func testAddingServerConfigurationPiggybackWithCustomConfigurationNonExpiredCache() {
    let configuration = ServerConfigurationFixtures.config(
      withDictionary: [
        "defaults": false,
        "timestamp": Date()
      ]
    )
    let graphRequest = GraphRequest(graphPath: name)
    serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest
    serverConfigurationProvider.stubbedServerConfiguration = configuration

    let connection = TestGraphRequestConnection()
    GraphRequestPiggybackManager.addServerConfigurationPiggyback(connection)

    XCTAssertEqual(
      connection.capturedRequests.count,
      0,
      "Should not add a server configuration request for a custom configuration with a non-expired cache"
    )
  }

  func testAddingServerConfigurationPiggybackWithCustomConfigurationMissingTimeout() {
    // Esoterica - the default timeout is nil in the default configuration
    let configuration = ServerConfigurationFixtures.config(withDictionary: ["defaults": false])
    let graphRequest = GraphRequest(graphPath: name)
    serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest
    serverConfigurationProvider.stubbedServerConfiguration = configuration

    let connection = TestGraphRequestConnection()
    GraphRequestPiggybackManager.addServerConfigurationPiggyback(connection)

    XCTAssertEqual(
      connection.capturedRequests.count,
      1,
      "Should add a server configuration request for a custom configuration with a missing cache timeout"
    )
  }

  func testAddingServerConfigurationPiggybackWithDefaultConfigurationMissingTimeout() {
    // Esoterica - the default timeout is nil in the default configuration
    let configuration = ServerConfigurationFixtures.config(withDictionary: ["defaults": true])
    let graphRequest = GraphRequest(graphPath: name)
    serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest
    serverConfigurationProvider.stubbedServerConfiguration = configuration

    let connection = TestGraphRequestConnection()
    GraphRequestPiggybackManager.addServerConfigurationPiggyback(connection)

    XCTAssertEqual(
      connection.capturedRequests.count,
      1,
      "Should add a server configuration request for a default configuration with a missing cache timeout"
    )
  }

  // MARK: - Helpers

  var twoDaysAgo: Date {
    let twoDaysInSeconds: TimeInterval = 2 * 60 * 60 * 24
    return Date(timeIntervalSinceNow: -twoDaysInSeconds)
  }

  var twoDayOldToken: AccessToken {
    SampleAccessTokens.create(withRefreshDate: twoDaysAgo)
  }

  func completeAccessTokenRefresh(
    token: AccessToken,
    results: [String: Any]?
  ) {
    settings.appID = token.appID
    TestAccessTokenWallet.currentAccessToken = token
    let connection = TestGraphRequestConnection()

    GraphRequestPiggybackManager.addRefreshPiggyback(connection, permissionHandler: nil)

    // The callback that sets the token ignores the first call to it
    // because it's waiting on the permissions call to complete first.
    // We can get around this for now by invoking the handler twice.
    connection.capturedCompletions.first?(connection, results, nil)
    connection.capturedCompletions.last?(connection, results, nil)
  }

  func validateRefreshedToken(
    _ refreshedToken: AccessToken?,
    expectedTokenString: String = SampleAccessTokens.validToken.tokenString,
    expectedRefreshDate: Date = Date(),
    expectedExpirationDate: Date = Date.distantFuture,
    expectedDataExpirationDate: Date = Date.distantFuture,
    expectedPermissions: Set<Permission> = [],
    expectedDeclinedPermissions: Set<Permission> = [],
    expectedExpiredPermissions: Set<Permission> = [],
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    let token = try XCTUnwrap(
      refreshedToken,
      "Must have an access token to assert against",
      file: file,
      line: line
    )
    XCTAssertEqual(
      token.tokenString,
      expectedTokenString,
      "A refreshed token should have the expected token string",
      file: file,
      line: line
    )
    XCTAssertEqual(
      token.refreshDate.timeIntervalSince1970,
      expectedRefreshDate.timeIntervalSince1970,
      accuracy: 1,
      "A refreshed token should have the expected refresh date",
      file: file,
      line: line
    )
    XCTAssertEqual(
      token.expirationDate,
      expectedExpirationDate,
      "A refreshed token should have the expected expiration date",
      file: file,
      line: line
    )
    XCTAssertEqual(
      token.dataAccessExpirationDate,
      expectedDataExpirationDate,
      "A refreshed token should have the expected data access expiration date",
      file: file,
      line: line
    )
    XCTAssertEqual(
      token.permissions,
      expectedPermissions,
      "A refreshed token should have the expected permissions",
      file: file,
      line: line
    )
    XCTAssertEqual(
      token.declinedPermissions,
      expectedDeclinedPermissions,
      "A refreshed token should have the expected declined permissions",
      file: file,
      line: line
    )
    XCTAssertEqual(
      token.expiredPermissions,
      expectedExpiredPermissions,
      "A refreshed token should have the expected expired permissions",
      file: file,
      line: line
    )
  }

  func completePermissionsRefresh(
    forAccessToken token: AccessToken,
    results: [String: Any]?,
    error: Error? = nil,
    permissionHandler: GraphRequestCompletion? = nil
  ) {
    settings.appID = token.appID
    TestAccessTokenWallet.currentAccessToken = token
    let connection = TestGraphRequestConnection()

    GraphRequestPiggybackManager.addRefreshPiggyback(
      connection,
      permissionHandler: permissionHandler
    )
    let tokenRefreshRequestCompletion = connection.capturedCompletions.first
    let permissionsRequestCompletion = connection.capturedCompletions.last

    tokenRefreshRequestCompletion?(connection, nil, nil)
    if let permissionCompletion = permissionsRequestCompletion {
      permissionCompletion(connection, results, error)
    }
  }

  func validateServerConfigurationRequestsEqual(
    _ actualRequest: GraphRequestProtocol,
    _ expectedRequest: GraphRequestProtocol,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    XCTAssertNotNil(
      actualRequest,
      "Adding a server configuration piggyback should add a request to fetch the server configuration",
      file: file,
      line: line
    )

    XCTAssertEqual(
      actualRequest.graphPath,
      expectedRequest.graphPath,
      "Should add a request with the expected graph path for fetching a server configuration",
      file: file,
      line: line
    )

    let actualParameters = try XCTUnwrap(actualRequest.parameters as? [String: String])
    let expectedParameters = try XCTUnwrap(expectedRequest.parameters as? [String: String])
    XCTAssertEqual(
      actualParameters,
      expectedParameters,
      "Should add a request with the correct parameters for fetching a server configuration",
      file: file,
      line: line
    )

    XCTAssertEqual(
      actualRequest.flags,
      expectedRequest.flags,
      "Should add a request with the correct flags for fetching a server configuration",
      file: file,
      line: line
    )
  }
}
