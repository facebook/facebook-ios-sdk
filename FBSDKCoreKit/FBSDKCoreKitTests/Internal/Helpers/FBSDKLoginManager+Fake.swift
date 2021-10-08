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
