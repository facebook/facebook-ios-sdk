/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

@objcMembers
class TestCrashHandler: NSObject, CrashHandlerProtocol {
  var wasAddObserverCalled = false
  var observer: CrashObserving?
  var wasClearCrashReportFilesCalled = false

  func addObserver(_ observer: CrashObserving) {
    wasAddObserverCalled = true
    self.observer = observer
    return
  }

  func clearCrashReportFiles() {
    wasClearCrashReportFilesCalled = true
  }
}
