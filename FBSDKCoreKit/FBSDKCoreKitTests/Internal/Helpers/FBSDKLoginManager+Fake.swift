/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objc(FBSDKLoginManager) // for NSClassFromString(@"FBSDKLoginManager")
@objcMembers
class FBSDKLoginManager: NSObject {
  static var capturedOpenUrl: URL?
  static var capturedSourceApplication: String?
  static var capturedAnnotation: String?
  static var stubbedOpenUrlSuccess = false

  var openUrlWasCalled = false
  var capturedCanOpenUrl: URL?
  var capturedCanOpenSourceApplication: String?
  var capturedCanOpenAnnotation: String?
  var stubbedCanOpenUrl = false
  var stubbedIsAuthenticationUrl = false
  private var urlPropagationMap = [String: Bool]()

  class func resetTestEvidence() {
    capturedOpenUrl = nil
    capturedSourceApplication = nil
    capturedAnnotation = nil
    stubbedOpenUrlSuccess = false
  }

  func stubShouldStopPropagationOfURL(_ url: URL, withValue value: Bool) {
    urlPropagationMap[url.absoluteString] = value
  }

  func shouldStopPropagationOfURL(_ url: URL) -> Bool {
    urlPropagationMap[url.absoluteString] ?? false
  }
}

// MARK: - FBSDKURLOpening

extension FBSDKLoginManager: URLOpening {
  public func application(
    _ application: UIApplication?,
    open url: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    openUrlWasCalled = true
    FBSDKLoginManager.capturedOpenUrl = url
    FBSDKLoginManager.capturedSourceApplication = sourceApplication
    FBSDKLoginManager.capturedAnnotation = annotation as? String
    return FBSDKLoginManager.stubbedOpenUrlSuccess
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
    capturedCanOpenUrl = url
    capturedCanOpenSourceApplication = sourceApplication
    capturedCanOpenAnnotation = annotation as? String
    return stubbedCanOpenUrl
  }

  public func isAuthenticationURL(_ url: URL) -> Bool {
    stubbedIsAuthenticationUrl
  }
}
