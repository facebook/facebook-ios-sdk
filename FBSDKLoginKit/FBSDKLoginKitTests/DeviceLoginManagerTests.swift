/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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

// swiftlint:disable:next type_body_length
class DeviceLoginManagerTests: XCTestCase {

  let fakeAppID = "123"
  let fakeClientToken = "abc"
  let permissions = ["email", "public_profile"]
  let redirectURL = URL(string: "https://www.example.com")
  let poller = TestDevicePoller()
  private let delegate = TestDeviceLoginManagerDelegate()
  lazy var factory = TestGraphRequestFactory()
  lazy var manager = DeviceLoginManager(
    permissions: permissions,
    enableSmartLogin: false,
    graphRequestFactory: factory,
    devicePoller: poller
  )

  override func setUp() {
    super.setUp()

    // This is a temporary hack to account for the fact that types need to be
    // initialized before being used, but doing that on the shared ApplicationDelegate
    // will create a host of 'real' types that will do things like start timers
    // and make network requests, and generally pollute the test environment.
    // This is mimicking the behavior of calling `didFinishLaunching` by configuring
    // the types that are needed for these test cases.
    InternalUtility.shared.isConfigured = true
    Settings.shared.isConfigured = true

    Settings.shared.appID = fakeAppID
    Settings.shared.clientToken = fakeClientToken

    manager.redirectURL = redirectURL
    manager.delegate = delegate
    manager.setCodeInfo(sampleCodeInfo())
  }

  override func tearDown() {
    Settings.shared.reset()

    super.tearDown()
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
      redirectURL?.absoluteString,
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
      "interval": expectedCodeInfo.pollingInterval
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
      self.sampleCodeInfo().identifier,
      "Should create a graph request with the expected code"
    )
    XCTAssertEqual(
      request.tokenString,
      self.fakeAppID + "|" + self.fakeClientToken
    )
  }

  func testStatusGraphRequestCompleteWithError() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, NSError(domain: "foo", code: 0, userInfo: nil))
    XCTAssertEqual(self.delegate.capturedLoginManager, manager)
    XCTAssertNotNil(self.delegate.capturedError)
  }

  func testStatusGraphRequestCompleteWithNoToken() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, [], nil)
    XCTAssertEqual(self.delegate.capturedLoginManager, self.manager)
    XCTAssertNotNil(self.delegate.capturedError)
  }

  func testStatusGraphRequestCompleteWithAccessToken() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)

    let result: [String: String] = [
      "access_token": SampleAccessTokens.validToken.tokenString,
      "expires_in": String(SampleAccessTokens.validToken.expirationDate.timeIntervalSinceNow),
      "data_access_expiration_time": String(
        SampleAccessTokens.validToken.dataAccessExpirationDate.timeIntervalSince1970
      )
    ]
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, result, nil)

    let request = try XCTUnwrap(factory.capturedRequests.last)
    XCTAssertEqual(request.tokenString, SampleAccessTokens.validToken.tokenString)
    XCTAssertEqual(request.graphPath, "me")
  }

  func testSchedulePollAfterCancel() throws {
    manager._schedulePoll(sampleCodeInfo().pollingInterval)

    self.manager.cancel()
    let result: [String: String] = [
      "access_token": SampleAccessTokens.validToken.tokenString,
    ]
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, result, nil)

    XCTAssertNil(self.delegate.capturedError)
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
      "id": "123"
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

    let result: [String: Any] = [
      "id": "123",
      "permissions": [
        "data": [
          [
            "permission": "public_profile",
            "status": "granted"
          ],
          [
            "permission": "email",
            "status": "granted"
          ],
          [
            "permission": "user_friends",
            "status": "declined"
          ],
          [
            "permission": "user_birthday",
            "status": "expired"
          ]
        ]
      ]
    ]
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      result,
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
    XCTAssertEqual(token.userID, "123")
    XCTAssertEqual(token.permissions, ["public_profile", "email"])
    XCTAssertEqual(token.declinedPermissions, ["user_friends"])
    XCTAssertEqual(token.expiredPermissions, ["user_birthday"])
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
    self.assertCancelResult()
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
    self.assertCancelResult()
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
} // swiftlint:disable:this file_length
