/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class InstrumentManagerTests: XCTestCase {

  var manager = InstrumentManager.shared
  let settings = TestSettings()
  let crashObserver = TestCrashObserver()
  let errorReporter = TestErrorReporter()
  let crashHandler = TestCrashHandler()
  let featureManager = TestFeatureManager()

  override class func setUp() {
    super.setUp()
    InstrumentManager.reset()
  }
  override func setUp() {
    super.setUp()

    manager.configure(
      featureChecker: featureManager,
      settings: settings,
      crashObserver: crashObserver,
      errorReporter: errorReporter,
      crashHandler: crashHandler
    )
  }
  override func tearDown() {
    super.tearDown()
    InstrumentManager.reset()
  }

  func testDefaultDependencies() {
    let manager = InstrumentManager.shared

    XCTAssertNil(
      manager.featureChecker,
      "Should not have a feature checker by default"
    )
    XCTAssertNil(
      manager.settings,
      "Should not have settings by default"
    )
    XCTAssertNil(
      manager.crashObserver,
      "Should not have a crash observer by default"
    )
    XCTAssertNil(
      manager.errorReporter,
      "Should not have an error reporter by default"
    )
    XCTAssertNil(
      manager.crashHandler,
      "Should not have a crash handler by default"
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
