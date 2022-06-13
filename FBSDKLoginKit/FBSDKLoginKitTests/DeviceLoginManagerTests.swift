/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

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
  var graphRequestFactory: TestGraphRequestFactory!
  var settings: TestSettings!
  var internalUtility: TestInternalUtility!
  var errorFactory: TestErrorFactory!
  var manager: DeviceLoginManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    poller = TestDevicePoller()
    delegate = TestDeviceLoginManagerDelegate()
    graphRequestFactory = TestGraphRequestFactory()
    settings = TestSettings()
    internalUtility = TestInternalUtility()
    errorFactory = TestErrorFactory()
    manager = DeviceLoginManager(
      permissions: permissions,
      enableSmartLogin: false
    )
    manager.setDependencies(
      .init(
        devicePoller: poller,
        errorFactory: errorFactory,
        graphRequestFactory: graphRequestFactory,
        internalUtility: internalUtility,
        settings: settings
      )
    )

    manager.redirectURL = redirectURL
    manager.delegate = delegate
    manager.codeInfo = sampleCodeInfo()
  }

  override func tearDown() {
    poller = nil
    delegate = nil
    graphRequestFactory = nil
    settings = nil
    internalUtility = nil
    errorFactory = nil
    manager = nil

    super.tearDown()
  }

  // MARK: Dependencies

  func testCreatingWithDependencies() throws {
    let dependencies = try manager.getDependencies()

    XCTAssertIdentical(
      dependencies.graphRequestFactory,
      graphRequestFactory,
      "A device login manager uses a provided graph request factory"
    )
    XCTAssertIdentical(
      dependencies.devicePoller as AnyObject,
      poller,
      "A device login manager uses a provided device poller"
    )
    XCTAssertIdentical(
      dependencies.settings,
      settings,
      "A device login manager uses a provided settings"
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      internalUtility,
      "A device login manager uses a provided internal utility"
    )
    XCTAssertIdentical(
      dependencies.errorFactory,
      errorFactory,
      "A device login manager uses a provided error factory"
    )
  }

  func testDefaultDependencies() throws {
    manager.resetDependencies()
    let dependencies = try manager.getDependencies()

    XCTAssertTrue(
      dependencies.graphRequestFactory is GraphRequestFactory,
      "A device login manager uses a concrete graph request factory by default"
    )
    XCTAssertTrue(
      dependencies.devicePoller is _DevicePoller,
      "A device login manager uses a concrete device poller by default"
    )
    XCTAssertIdentical(
      dependencies.settings,
      Settings.shared,
      "A device login manager uses the shared settings by default"
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      InternalUtility.shared,
      "A device login manager uses the shared internal utility by default"
    )
    XCTAssertTrue(
      dependencies.errorFactory is ErrorFactory,
      "A device login manager uses a concrete error factory by default"
    )
  }

  // MARK: Start

  func testStartGraphRequestCreation() throws {
    manager.start()

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)

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

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, NSError(domain: "foo", code: 0, userInfo: nil))

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testStartGraphRequestCompleteWithEmptyResponse() throws {
    manager.start()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
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

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
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
    manager.schedulePoll(interval: codeInfo.pollingInterval)

    XCTAssertEqual(poller.capturedInterval, codeInfo.pollingInterval)

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
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
    manager.schedulePoll(interval: sampleCodeInfo().pollingInterval)

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, NSError(domain: "foo", code: 0, userInfo: nil))
    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testStatusGraphRequestCompleteWithNoToken() throws {
    manager.schedulePoll(interval: sampleCodeInfo().pollingInterval)
    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, [], nil)
    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testStatusGraphRequestCompleteWithAccessToken() throws {
    manager.schedulePoll(interval: sampleCodeInfo().pollingInterval)

    let result: [String: String] = [
      "access_token": SampleAccessTokens.validToken.tokenString,
      "expires_in": String(SampleAccessTokens.validToken.expirationDate.timeIntervalSinceNow),
      "data_access_expiration_time": String(
        SampleAccessTokens.validToken.dataAccessExpirationDate.timeIntervalSince1970
      ),
    ]
    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, result, nil)

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.last)
    XCTAssertEqual(request.tokenString, SampleAccessTokens.validToken.tokenString)
    XCTAssertEqual(request.graphPath, "me")
  }

  func testSchedulePollAfterCancel() throws {
    manager.schedulePoll(interval: sampleCodeInfo().pollingInterval)

    manager.cancel()
    let result: [String: String] = [
      "access_token": SampleAccessTokens.validToken.tokenString,
    ]
    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, result, nil)

    XCTAssertNil(delegate.capturedError)
    XCTAssertEqual(
      graphRequestFactory.capturedRequests.count,
      1,
      "Should not be making another graph request to fetch permissions"
    )
  }

  // MARK: _notifyToken

  func testNotifyTokenGraphRequestCreation() throws {
    manager.notifyDelegate(
      token: SampleAccessTokens.validToken.tokenString,
      expirationDate: SampleAccessTokens.validToken.expirationDate,
      dataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.last)
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
    manager.notifyDelegate(
      token: SampleAccessTokens.validToken.tokenString,
      expirationDate: SampleAccessTokens.validToken.expirationDate,
      dataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )
    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, NSError(domain: "foo", code: 0, userInfo: nil))

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testNotifyTokenGraphRequestCompleteWithNoUserID() throws {
    let result: [String: Any] = [
      "permissions": ["data": []],
    ]

    manager.notifyDelegate(
      token: SampleAccessTokens.validToken.tokenString,
      expirationDate: SampleAccessTokens.validToken.expirationDate,
      dataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )
    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      result,
      nil
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testNotifyTokenGraphRequestCompleteWithNoPermissions() throws {
    manager.notifyDelegate(
      token: SampleAccessTokens.validToken.tokenString,
      expirationDate: SampleAccessTokens.validToken.expirationDate,
      dataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
    )

    let result: [String: Any] = [
      "id": "123",
    ]
    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      result,
      nil
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNotNil(delegate.capturedError)
  }

  func testNotifyTokenGraphRequestCompleteWithPermissionsAndUserID() throws {
    manager.notifyDelegate(
      token: SampleAccessTokens.validToken.tokenString,
      expirationDate: SampleAccessTokens.validToken.expirationDate,
      dataAccessExpirationDate: SampleAccessTokens.validToken.dataAccessExpirationDate
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

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
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
    manager.notifyDelegate(
      token: nil,
      expirationDate: nil,
      dataAccessExpirationDate: nil
    )

    XCTAssertEqual(graphRequestFactory.capturedRequests.count, 0)
    guard let loginResult = delegate.capturedResult else {
      XCTFail("Should receive an login result")
      return
    }
    XCTAssert(loginResult.isCancelled)
    XCTAssertNil(loginResult.accessToken)
  }

  // MARK: _processError

  func testProcessErrorAuthorizationPending() throws {
    manager.processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.authorizationPending.rawValue]
      )
    )

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
    XCTAssertEqual(
      request.graphPath,
      "device/login_status",
      "Should create a graph request with the expected graph path"
    )
  }

  func testProcessErrorCodeExpired() throws {
    manager.processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.codeExpired.rawValue]
      )
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNil(graphRequestFactory.capturedRequests.first)
    try assertCancelResult()
  }

  func testProcessErrorAuthorizationDeclined() throws {
    manager.processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.authorizationDeclined.rawValue]
      )
    )

    XCTAssertEqual(delegate.capturedLoginManager, manager)
    XCTAssertNil(graphRequestFactory.capturedRequests.first)
    try assertCancelResult()
  }

  func testProcessErrorExcessivePolling() throws {
    manager.processError(
      NSError(
        domain: "foo",
        code: 0,
        userInfo: [GraphRequestErrorGraphErrorSubcodeKey: DeviceLoginError.excessivePolling.rawValue]
      )
    )

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
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

  func assertCancelResult(file: StaticString = #file, line: UInt = #line) throws {
    let loginResult = try XCTUnwrap(
      delegate.capturedResult,
      "Should receive an login result",
      file: file,
      line: line
    )

    XCTAssert(loginResult.isCancelled, file: file, line: line)
    XCTAssertNil(loginResult.accessToken, file: file, line: line)
  }
}
