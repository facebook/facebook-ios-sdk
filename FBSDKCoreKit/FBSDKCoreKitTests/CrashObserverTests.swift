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

import FBSDKCoreKit
import TestTools
import XCTest

class CrashObserversTest: XCTestCase {

  var requestProvider: TestGraphRequestFactory! // swiftlint:disable:this implicitly_unwrapped_optional
  var crashObserver: CrashObserver! // swiftlint:disable:this implicitly_unwrapped_optional
  var settings: TestSettings! // swiftlint:disable:this implicitly_unwrapped_optional
  let featureManager = TestFeatureManager()

  override func setUp() {
    super.setUp()
    requestProvider = TestGraphRequestFactory()
    settings = TestSettings()
    crashObserver = CrashObserver(
      featureChecker: featureManager,
      graphRequestProvider: requestProvider,
      settings: settings
    )
  }

  func testDefaultCrashObserverSettings() {
     XCTAssertTrue(
       CrashObserver().settings is Settings,
       "Should use the shared settings instance by default"
     )
   }

  func testCreatingWithCustomSettings() {
    XCTAssertTrue(
      crashObserver.settings is TestSettings,
      "Should be able to create with custom settings"
    )
  }

  func testDidReceiveCrashLogs() {
    crashObserver.didReceiveCrashLogs([])
    XCTAssertEqual(featureManager.capturedFeatures, [])

    let processedCrashLogs = CrashObserversTest.getCrashLogs()

    crashObserver.didReceiveCrashLogs(processedCrashLogs)

    XCTAssertTrue(
      featureManager.capturedFeatures.contains(SDKFeature.crashShield),
      "Receiving crash logs should check to see if the crash shield feature is enabled"
    )
  }

  static func getCrashLogs() -> [[String: Any]] {
    let callstack = ["(4 DEV METHODS)",
    "+[FBSDKCodelessIndexer crash]+84",
    "(22 DEV METHODS)"]

    let crashLogs = [[
      "callstack": callstack,
      "reason": "NSInternalInconsistencyException",
      "fb_sdk_version": "5.6.0",
      "timestamp": "1572036095",
      "app_id": "2416630768476176",
      "device_model": "iPad5,3",
      "device_os": "ios",
      "device_os_version": "13.1.3",
    ]]
    return crashLogs
  }
}
