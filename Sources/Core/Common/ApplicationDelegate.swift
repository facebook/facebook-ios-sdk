// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import Foundation
import UIKit
import FBSDKCoreKit

/**
 The ApplicationDelegate is designed to post process the results from Facebook Login or Facebook Dialogs
 (or any action that requires switching over to the native Facebook app or Safari).

 The methods in this class are designed to mirror those in UIApplicationDelegate, and you
 should call them in the respective methods in your AppDelegate implementation.
 */
public final class ApplicationDelegate {
  private let delegate: FBSDKApplicationDelegate = FBSDKApplicationDelegate.sharedInstance()

  /// Returns the singleton instance of an application delegate.
  public static let shared = ApplicationDelegate()

  private init() { }
}

extension ApplicationDelegate {
  /**
   Call this function from the `UIApplicationDelegate.application(application:didFinishLaunchingWithOptions:)` function
   of the AppDelegate of your app It should be invoked for the proper initialization of the Facebook SDK.

   - parameter application:   The application as passed to `UIApplicationDelegate`.
   - parameter launchOptions: The launchOptions as passed to `UIApplicationDelegate`.

   - returns: `true` if the url contained in the `launchOptions` was intended for the Facebook SDK, otherwise - `false`.
   */
  public func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
    return delegate.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /**
   Call this function from the `UIApplicationDelegate.application(application:openURL:sourceApplication:annotation:)` function
   of the AppDelegate for your app. It should be invoked for the proper processing of responses during interaction
   with the native Facebook app or Safari as part of SSO authorization flow or Facebook dialogs.

   - parameter application:       The application as passed to `UIApplicationDelegate`.
   - parameter url:               The URL as passed to `UIApplicationDelegate`.
   - parameter sourceApplication: The sourceApplication as passed to `UIApplicationDelegate`.
   - parameter annotation:        The annotation as passed to `UIApplicationDelegate`.

   - returns: `true` if the url was intended for the Facebook SDK, otherwise - `false`.
   */
  public func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    return delegate.application(application, openURL:url, sourceApplication:sourceApplication, annotation:annotation)
  }
}
