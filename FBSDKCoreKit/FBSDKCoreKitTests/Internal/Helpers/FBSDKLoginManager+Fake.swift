/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
@objc(FBSDKLoginManager) // for NSClassFromString(@"FBSDKLoginManager")
final class FBSDKLoginManager: NSObject {
  static var capturedOpenURL: URL?
  static var capturedSourceApplication: String?
  static var capturedAnnotation: String?
  static var stubbedOpenURLSuccess = false

  var openURLWasCalled = false
  var capturedCanOpenURL: URL?
  var capturedCanOpenSourceApplication: String?
  var capturedCanOpenAnnotation: String?
  var stubbedCanOpenURL = false
  var stubbedIsAuthenticationURL = false
  private var urlPropagationMap = [String: Bool]()

  class func resetTestEvidence() {
    capturedOpenURL = nil
    capturedSourceApplication = nil
    capturedAnnotation = nil
    stubbedOpenURLSuccess = false
  }

  func stubShouldStopPropagationOfURL(_ url: URL, withValue value: Bool) {
    urlPropagationMap[url.absoluteString] = value
  }

  func shouldStopPropagationOfURL(_ url: URL) -> Bool {
    urlPropagationMap[url.absoluteString] ?? false
  }
}

// MARK: URLOpening

extension FBSDKLoginManager: URLOpening {
  public func application(
    _ application: UIApplication?,
    open url: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    openURLWasCalled = true
    FBSDKLoginManager.capturedOpenURL = url
    FBSDKLoginManager.capturedSourceApplication = sourceApplication
    FBSDKLoginManager.capturedAnnotation = annotation as? String
    return FBSDKLoginManager.stubbedOpenURLSuccess
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    // empty
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    capturedCanOpenURL = url
    capturedCanOpenSourceApplication = sourceApplication
    capturedCanOpenAnnotation = annotation as? String
    return stubbedCanOpenURL
  }

  public func isAuthenticationURL(_ url: URL) -> Bool {
    stubbedIsAuthenticationURL
  }
}
