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

class InstrumentManagerTests: XCTestCase {

  var manager: InstrumentManager! // swiftlint:disable:this implicitly_unwrapped_optional
  let settings = TestSettings()
  let crashObserver = TestCrashObserver()
  let errorReporter = TestErrorReport()
  let crashHandler = TestCrashHandler()
  let featureManager = TestFeatureManager()

  override func setUp() {
    super.setUp()

    manager = InstrumentManager(
      featureCheckerProvider: featureManager,
      settings: settings,
      crashObserver: crashObserver,
      errorReport: errorReporter,
      crashHandler: crashHandler
    )
  }

  func testDefaultDependencies() {
    let manager = InstrumentManager.shared

    XCTAssertTrue(
      manager.featureChecker is FeatureManager,
      "Should use the expected feature checker type by default"
    )
    XCTAssertEqual(
      ObjectIdentifier(manager.settings),
      ObjectIdentifier(Settings.shared),
      "Should use the shared settings instance by default"
    )
    XCTAssertEqual(
      ObjectIdentifier(manager.crashObserver),
      ObjectIdentifier(CrashObserver.shared),
      "Should use the shared crash observer instance by default"
    )
    XCTAssertEqual(
      ObjectIdentifier(manager.errorReport),
      ObjectIdentifier(ErrorReport.shared),
      "Should use the shared error report instance by default"
    )
    XCTAssertEqual(
      ObjectIdentifier(manager.crashHandler),
      ObjectIdentifier(CrashHandler.shared),
      "Should use the shared Crash Handler instance by default"
    )
  }

  func testEnablingWithBothEnabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = true

    manager.enable()

    featureManager.completeCheck(forFeature: .crashReport, with: true)
    featureManager.completeCheck(forFeature: .errorReport, with: true)

    XCTAssertTrue(crashHandler.wasAddObserverCalled)
    XCTAssertNotNil(crashHandler.observer)
    XCTAssertTrue(errorReporter.wasEnableCalled)
  }

  func testEnablingWithAutoLoggingEnabledAndFeaturesDisabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = true

    manager.enable()

    featureManager.completeCheck(forFeature: .crashReport, with: false)
    featureManager.completeCheck(forFeature: .errorReport, with: false)

    XCTAssertFalse(crashHandler.wasAddObserverCalled)
    XCTAssertNil(crashHandler.observer)
    XCTAssertFalse(errorReporter.wasEnableCalled)
  }

  func testEnablingWithAutoLoggingDisabledAndFeaturesEnabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = false

    manager.enable()

    featureManager.completeCheck(forFeature: .crashReport, with: true)
    featureManager.completeCheck(forFeature: .errorReport, with: true)

    XCTAssertFalse(crashHandler.wasAddObserverCalled)
    XCTAssertNil(crashHandler.observer)
    XCTAssertFalse(errorReporter.wasEnableCalled)
  }

  func testEnablingWithBothDisabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = false

    manager.enable()

    featureManager.completeCheck(forFeature: .crashReport, with: false)
    featureManager.completeCheck(forFeature: .errorReport, with: false)

    XCTAssertFalse(crashHandler.wasAddObserverCalled)
    XCTAssertNil(crashHandler.observer)
    XCTAssertFalse(errorReporter.wasEnableCalled)
  }
}
