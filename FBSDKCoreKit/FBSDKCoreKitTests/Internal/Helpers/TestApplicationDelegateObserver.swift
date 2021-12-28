/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestApplicationDelegateObserver: NSObject, FBSDKApplicationObserving {
  var didFinishLaunchingCallCount = 0
  var capturedLaunchOptions: [UIApplication.LaunchOptionsKey: Any]?
  var wasWillResignActiveCalled = false

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    didFinishLaunchingCallCount += 1
    capturedLaunchOptions = launchOptions
    return true
  }

  func applicationWillResignActive(_ application: UIApplication?) {
    wasWillResignActiveCalled = true
  }
}
