// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if BUCK
import FacebookCore
#endif

import TestTools
import XCTest

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
    GraphRequestConnection.setCanMakeRequests()
    InternalUtility.shared.isConfigured = true
    Settings.shared.isConfigured = true

    Settings.appID = fakeAppID
    Settings.clientToken = fakeClientToken

    manager.redirectURL = redirectURL
    manager.delegate = delegate
    manager.setCodeInfo(sampleCodeInfo())
  }

  override func tearDown() {
    Settings.reset()

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
      "interval": String(expectedCodeInfo.pollingInterval)
    ]

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

  // MARK: Helpers

  func sampleCodeInfo() -> DeviceLoginCodeInfo {
    return DeviceLoginCodeInfo(
      identifier: "identifier",
      loginCode: "loginCode",
      verificationURL: URL(string: "https://www.facebook.com")!,
      expirationDate: Date.distantFuture,
      pollingInterval: 0
    )
  }
}
