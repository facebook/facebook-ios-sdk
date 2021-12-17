/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class TestInternalUtility: InternalUtilityProtocol {
  var scheme: String?
  var host: String?
  var path: String?
  var queryParameters: [String: String]?
  var isFacebookAppInstalled = false
  var isUnity = false

  func url(withScheme scheme: String, host: String, path: String, queryParameters: [String: String]) throws -> URL {
    self.scheme = scheme
    self.host = host
    self.path = path
    self.queryParameters = queryParameters
    var returnUrlComponents = URLComponents()
    returnUrlComponents.scheme = scheme
    returnUrlComponents.host = host
    returnUrlComponents.path = path

    return returnUrlComponents.url ?? SampleURLs.valid
  }

  func appURL(
    withHost host: String,
    path: String,
    queryParameters: [String: String]
  ) throws -> URL {
    SampleURLs.valid
  }

  func facebookURL(
    withHostPrefix hostPrefix: String,
    path: String,
    queryParameters: [String: String]
  ) throws -> URL {
    SampleURLs.valid
  }

  func registerTransientObject(_ object: Any) {}

  func unregisterTransientObject(_ object: Any) {}

  func checkRegisteredCanOpenURLScheme(_ urlScheme: String) {}

  func validateURLSchemes() {}

  func extendDictionary(withDataProcessingOptions parameters: NSMutableDictionary) {}

  func hexadecimalString(from data: Data) -> String? {
    nil
  }
}

enum URLConstants {
  case mSite
  case appSwitch(appID: String)

  static let host = "fb.gg"
  var path: String {
    switch self {
    case .mSite:
      return "/dialog/choosecontext/"
    case let .appSwitch(appID):
      return String(format: "/dialog/choosecontext/%@/", appID)
    }
  }

  static let queryParameterFilter = "filter"
  static let queryParameterMinSize = "min_size"
  static let queryParameterMaxSize = "max_size"
  static let mSiteQueryParameterPath = "path"
  static let mSiteQueryParameterParams = "params"
}
