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

class TestInternalUtility: InternalUtilityProtocol {
  var scheme: String?
  var host: String?
  var path: String?
  var queryParameters: [AnyHashable: Any]?
  var isFacebookAppInstalled = false

  init(isFacebookAppInstalled: Bool) {
    self.isFacebookAppInstalled = isFacebookAppInstalled
  }

  func url(withScheme scheme: String, host: String, path: String, queryParameters: [AnyHashable: Any]) throws -> URL {
    self.scheme = scheme
    self.host = host
    self.path = path
    self.queryParameters = queryParameters
    var returnUrlComponents = URLComponents()
    returnUrlComponents.scheme = scheme
    returnUrlComponents.host = host
    returnUrlComponents.path = path

    return returnUrlComponents.url ?? URL(string: "www.facebook.com")!// swiftlint:disable:this force_unwrapping
  }

  func registerTransientObject(_ object: Any) {}

  func unregisterTransientObject(_ object: Any) {}

  func checkRegisteredCanOpenURLScheme(_ urlScheme: String) {}
}

enum URLConstants {
  case mSite
  case appSwitch(appID: String)

  static let scheme = "https"
  static let host = "fb.gg"
  var path: String {
    switch self {
    case .mSite:
      return "/dialog/choosecontext/"
    case .appSwitch(let appID):
      return String(format: "/dialog/choosecontext/%@/", appID)
    }
  }
  static let queryParameterFilter = "filter"
  static let queryParameterMinSize = "min_size"
  static let queryParameterMaxSize = "max_size"
  static let mSiteQueryParameterPath = "path"
  static let mSiteQueryParameterParams = "params"
}
