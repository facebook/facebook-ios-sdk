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

@objcMembers
public class TestInternalUtility: NSObject, AppAvailabilityChecker, URLHosting, AppURLSchemeProviding {
  public var stubbedScheme = "No stub app url scheme provided"
  public var validateURLSchemesCalled = false

  public var isFacebookAppInstalled = false

  public var isMessengerAppInstalled = false

  public func facebookURL(
    withHostPrefix hostPrefix: String,
    path: String,
    queryParameters: [String: Any],
    error errorRef: NSErrorPointer
  ) -> URL {
    URL(string: "facebook.com")! // swiftlint:disable:this force_unwrapping
  }

  public func appURL(
    withHost host: String,
    path: String,
    queryParameters: [String: Any],
    error errorRef: NSErrorPointer
  ) -> URL {
    URL(string: "example.com")! // swiftlint:disable:this force_unwrapping
  }

  public func appURLScheme() -> String {
    stubbedScheme
  }

  public func validateURLSchemes() {
    validateURLSchemesCalled = true
  }
}
