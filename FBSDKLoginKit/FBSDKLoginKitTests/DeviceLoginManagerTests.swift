/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if BUCK
import FacebookCore
#endif

import TestTools
import XCTest

final class DeviceLoginManagerTests: XCTestCase {

  let fakeAppID = "123"
  let fakeClientToken = "abc"
  let permissions = ["email", "public_profile"]
  let redirectURL = URL(string: "https://www.example.com")! // swiftlint:disable:this force_unwrapping

  // swiftlint:disable implicitly_unwrapped_optional
  var poller: TestDevicePoller!
  var delegate: TestDeviceLoginManagerDelegate!
  var factory: TestGraphRequestFactory!
  var settings: TestSettings!
  var internalUtility: TestInternalUtility!
  var manager: DeviceLoginManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    poller = TestDevicePoller()
    delegate = TestDeviceLoginManagerDelegate()
    factory = TestGraphRequestFactory()
    settings = TestSettings()
    internalUtility = TestInternalUtility()
    manager = DeviceLoginManager(
      permissions: permissions,
      enableSmartLogin: false,
      graphRequestFactory: factory,
      devicePoller: poller,
      settings: settings,
      internalUtility: internalUtility
    )

    manager.redirectURL = redirectURL
    manager.delegate = delegate
    manager.setCodeInfo(sampleCodeInfo())
  }

  override func tearDown() {
    poller = nil
    delegate = nil
    factory = nil
    settings = nil
    internalUtility = nil
    manager = nil

    super.tearDown()
  }

  // MARK: Dependencies

  func testCreatingWithDependencies() {
    XCTAssertIdentical(
      manager.graphRequestFactory,
      factory,
      "A device login manager should be created with the provided graph request factory"
    )
    XCTAssertIdentical(
      manager.devicePoller,
      poller,
      "A device login manager should be created with the provided device poller"
    )
    XCTAssertIdentical(
      manager.settings,
      settings,
      "A device login manager should be created with the provided settings"
    )
    XCTAssertIdentical(
      manager.internalUtility,
      internalUtility,
      "A device login manager should be created with the provided internal utility"
    )
  }

  func testDefaultDependencies() {
    manager = DeviceLoginManager(
      permissions: permissions,
      enableSmartLogin: false
    )

    XCTAssertTrue(
      manager.graphRequestFactory is GraphRequestFactory,
      "A device login manager should be created with a concrete graph request factory by default"
    )
    XCTAssertTrue(
      manager.devicePoller is DevicePoller,
      "A device login manager should be created with a concrete device poller by default"
    )
    XCTAssertIdentical(
      manager.settings,
      Settings.shared,
      "A device login manager should be created with the shared settings by default"
    )
    XCTAssertIdentical(
      manager.internalUtility,
      InternalUtility.shared,
      "A device login manager should be created with the shared internal utility by default"
    )
  }

  // MARK: Start

  func testStartGraphRequestCreation() throws {
    manager.start()

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(
      request.graphPath,
      "device/login",
      "Should create a graph request with the expected graph path"
    )
    XCTAssertEqual(
      request.parameters["scope"] as? String,
      permissions.joined(separator: ","),
      "Should create a graph request with the expected scope"
    )
    XCTAssertEqual(
      request.parameters["redirect_uri"] as? String,
      redirectURL.absoluteString,
      "Should create a graph request with the expected redirect URL"
    )
    XCTAssertNotNil(
      request.parameters["device_info"],
      "Should create a graph request with device info"
    )
  }

  func testStartGraphRequestCompleteWithError() throws {
    manager.start()

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, NSError(domain: "foo", code: 0, userInfo: nil))

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testStartGraphRequestCompleteWithEmptyResponse() throws {
    manager.start()

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, [], nil)

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testStartGraphRequestCompleteWithCodeInfo() throws {
    manager.start()
    let expectedCodeInfo = sampleCodeInfo()
    let result = [
      "code": expectedCodeInfo.identifier,
      "user_code": expectedCodeInfo.loginCode,
      "verification_uri": expectedCodeInfo.verificationURL.absoluteString,
      "expires_in": String(expectedCodeInfo.expirationDate.timeIntervalSinceNow),
      "interval": expectedCodeInfo.pollingInterval,
    ] as [String: Any]

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, result, nil)

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNil(delegate.capturedError)
    XCTAssertNil(delegate.capturedResult)

    let codeInfo = try XCTUnwrap(delegate.capturedCodeInfo, "Should receive code info")

    XCTAssertEqual(codeInfo.identifier, expectedCodeInfo.identifier)
    XCTAssertEqual(codeInfo.loginCode, expectedCodeInfo.loginCode)
    XCTAssertEqual(codeInfo.verificationURL, expectedCodeInfo.verificationURL)
    XCTAssertEqual(
      codeInfo.expirationDate.timeIntervalSince1970,
      expectedCodeInfo.expirationDate.timeIntervalSince1970,
      accuracy: 1
    )
    XCTAssertEqual(codeInfo.pollingInterval, expectedCodeInfo.pollingInterval)
  }

  // MARK: _schedulePoll

  func testStatusGraphRequestCreation() throws {
    let tokenString = "sample-token"
    internalUtility.stubbedRequiredClientAccessToken = tokenString
    let codeInfo = sampleCodeInfo()
    manager._schedulePoll(codeInfo.pollingInterval)

    XCTAssertEqual(poller.capturedInterval, codeInfo.pollingInterval)

    let request = try XCTUnwrap(factory.capturedRequests.first)
    XCTAssertEqual(
      request.graphPath,
      "device/login_status",
      "Should create a graph request with the expected graph path"
    )
    let parameters = request.parameters
    XCTAssertEqual(
      parameters["code"] as? String,
      sampleCodeInfo().identifier,
      "Should create a graph request with the expected code"
    )
    XCTAssertEqual(
      request.tokenString,
      tokenString
    )
  }

  func testStatusGraphRequestCompleteWithError() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, NSError(domain: "foo", code: 0, userInfo: nil))
    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testStatusGraphRequestCompleteWithNoToken() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, [], nil)
    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testStatusGraphRequestCompleteWithAccessToken() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)

    let result: [String: String] = [
      "access_token": SampleAccessTokens.validToken.tokenString,
      "expires_in": String(SampleAccessTokens.validToken.expirationDate.timeIntervalSinceNow),
      "data_access_expiration_time": String(
        SampleAccessTokens.validToken.dataAccessExpirationDate.timeIntervalSince1970
      ),
    ]
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, result, nil)

    let request = try XCTUnwrap(factory.capturedRequests.last)
    XCTAssertEqual(request.tokenString, SampleAccessTokens.validToken.tokenString)
    XCTAssertEqual(request.graphPath, "me")
  }

  func testSchedulePollAfterCancel() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)

    manager.cancel()
    let result: [String: String] = [
      "access_token": SampleAccessTokens.validToken.tokenString,
    ]
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, result, nil)

    XCTAssertNil(delegate.capturedError)
    XCTAssertEqual(
      factory.capturedRequests.count,
      1,
      "Should not be making another graph request to fetch permissions"
    )
  }

  // MARK: _notifyToken

  func testNotifyTokenGraphRequestCreation() throws {
    manager._notifyToken(
      SampleAccessTokens.validToken.tokenString,
      withExpirationDate: SampleAccessTokens.validToken.expirationDate,
      withDataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )

    let request = try XCTUnwrap(factory.capturedRequests.last)
    XCTAssertEqual(
      request.graphPath,
      "me",
      "Should create a graph request with the expected graph path"
    )
    let parameters = request.parameters
    XCTAssertEqual(
      parameters["fields"] as? String,
      "id,permissions",
      "Should create a graph request with the expected fields"
    )
    XCTAssertEqual(
      request.tokenString,
      SampleAccessTokens.validToken.tokenString,
      "Should create a graph request with the expected token string"
    )
  }

  func testNotifyTokenGraphRequestCompleteWithError() throws {
    manager._notifyToken(
      SampleAccessTokens.validToken.tokenString,
      withExpirationDate: SampleAccessTokens.validToken.expirationDate,
      withDataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, NSError(domain: "foo", code: 0, userInfo: nil))

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testNotifyTokenGraphRequestCompleteWithNoUserID() throws {
    let result: [String: Any] = [
      "permissions": ["data": []],
    ]

    manager._notifyToken(
      SampleAccessTokens.validToken.tokenString,
      withExpirationDate: SampleAccessTokens.validToken.expirationDate,
      withDataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      result,
      nil
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testNotifyTokenGraphRequestCompleteWithNoPermissions() throws {
    manager._notifyToken(
      SampleAccessTokens.validToken.tokenString,
      withExpirationDate: SampleAccessTokens.validToken.expirationDate,
      withDataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )

    let result: [String: Any] = [
      "id": "123",
    ]
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      result,
      nil
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testNotifyTokenGraphRequestCompleteWithPermissionsAndUserID() throws {
    manager._notifyToken(
      SampleAccessTokens.validToken.tokenString,
      withExpirationDate: SampleAccessTokens.validToken.expirationDate,
      withDataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )

    let response: [String: Any] = [
      "id": "123",
      "permissions": [
        "marker": true,
      ],
    ]
    let granted = ["public_profile", "email"]
    let declined = ["user_friends"]
    let expired = ["user_birthday"]
    internalUtility.stubbedGrantedPermissions = granted
    internalUtility.stubbedDeclinedPermissions = declined
    internalUtility.stubbedExpiredPermissions = expired

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      response,
      nil
    )

    guard let loginResult = delegate.capturedResult else {
      XCTFail("Should receive a login result")
      return
    }
    XCTAssertFalse(loginResult.isCancelled)
    guard let token = loginResult.accessToken else {
      XCTFail("Should receive an AccessToken within login result")
      return
    }
    let marker = try XCTUnwrap(internalUtility.capturedExtractPermissionsResponse?["marker"] as? Bool)
    XCTAssertTrue(
      marker,
      "The response's permissions should be passed to the internal utility"
    )
    XCTAssertEqual(token.userID, "123")
    XCTAssertEqual(
      Set(token.permissions.map(\.name)),
      Set(granted)
    )
    XCTAssertEqual(
      Set(token.declinedPermissions.map(\.name)),
      Set(declined)
    )
    XCTAssertEqual(
      Set(token.expiredPermissions.map(\.name)),
      Set(expired)
    )
    XCTAssertEqual(token, AccessToken.current)
  }

  func testNotifyTokenWithNoTokenString() {
    manager._notifyToken(
      nil,
      withExpirationDate: nil,
      withDataAccessExpirationDate: nil
    )

    XCTAssertEqual(factory.capturedRequests.count, 0)
    guard let loginResult = delegate.capturedResult else {
      XCTFail("Should receive an login result")
      return
    }
    XCTAssert(loginResult.isCancelled)
    XCTAssertNil(loginResult.accessToken)
  }

  // MARK: _processError

  func testProcessErrorAuthorizationPending() throws {
    manager._processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.authorizationPending.rawValue]
      )
    )

    let request = try XCTUnwrap(factory.capturedRequests.first)
    XCTAssertEqual(
      request.graphPath,
      "device/login_status",
      "Should create a graph request with the expected graph path"
    )
  }

  func testProcessErrorCodeExpired() {
    manager._processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.codeExpired.rawValue]
      )
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNil(factory.capturedRequests.first)
    assertCancelResult()
  }

  func testProcessErrorAuthorizationDeclined() {
    manager._processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.authorizationDeclined.rawValue]
      )
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNil(factory.capturedRequests.first)
    assertCancelResult()
  }

  func testProcessErrorExcessivePolling() throws {
    manager._processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.excessivePolling.rawValue]
      )
    )

    let request = try XCTUnwrap(factory.capturedRequests.first)
    XCTAssertEqual(
      request.graphPath,
      "device/login_status",
      "Should create a graph request with the expected graph path"
    )
  }

  // MARK: Helpers

  func sampleCodeInfo() -> DeviceLoginCodeInfo {
    DeviceLoginCodeInfo(
      identifier: "identifier",
      loginCode: "loginCode",
      verificationURL: URL(string: "https://www.facebook.com")!, // swiftlint:disable:this force_unwrapping
      expirationDate: Date.distantFuture,
      pollingInterval: 10
    )
  }

  func assertCancelResult() {
    guard let loginResult = delegate.capturedResult else {
      XCTFail("Should receive an login result")
      return
    }
    XCTAssert(loginResult.isCancelled)
    XCTAssertNil(loginResult.accessToken)
  }
}
