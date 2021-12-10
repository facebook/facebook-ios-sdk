/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestTimeSpentRecorder: NSObject, SourceApplicationTracking, TimeSpentRecording {

  // swiftlint:disable identifier_name
  var restoreWasCalled = false
  var suspendWasCalled = false
  var capturedCalledFromActivateApp = false
  var capturedSetSourceApplication: String?
  var capturedSetSourceApplicationURL: URL?
  var capturedSetSourceApplicationFromAppLink: String?
  var capturedIsFromAppLink = false
  var wasRegisterAutoResetSourceApplicationCalled = false

  func suspend() {
    suspendWasCalled = true
  }

  func restore(_ calledFromActivateApp: Bool) {
    restoreWasCalled = true
    capturedCalledFromActivateApp = calledFromActivateApp
  }

  func setSourceApplication(_ sourceApplication: String?, open url: URL?) {
    capturedSetSourceApplication = sourceApplication
    capturedSetSourceApplicationURL = url
  }

  func setSourceApplication(_ sourceApplication: String?, isFromAppLink: Bool) {
    capturedSetSourceApplicationFromAppLink = sourceApplication
    capturedIsFromAppLink = isFromAppLink
  }

  func registerAutoResetSourceApplication() {
    wasRegisterAutoResetSourceApplicationCalled = true
  }
}
