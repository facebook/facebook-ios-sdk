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
import XCTest

class CrashObserversTest: XCTestCase {

  func testDidReceiveCrashLogs() {
    let featureManagerProvider = TestFeatureManagerProvider.create(withStubbedFeatureManager: TestFeatureManager.self)

    let crashObserver = CrashObserver(featureManagerProvider: featureManagerProvider)

    crashObserver.didReceiveCrashLogs([])
    XCTAssertEqual(TestFeatureManager.capturedFeatures, [])

    featureManagerProvider.stubbedFeatureManager?.check(SDKFeature.crashShield, completionBlock: nil)

    let processedCrashLogs = CrashObserversTest.getCrashLogs()

    crashObserver.didReceiveCrashLogs(processedCrashLogs)

    XCTAssertTrue(
      TestFeatureManager.capturedFeatures.contains(SDKFeature.crashShield),
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
