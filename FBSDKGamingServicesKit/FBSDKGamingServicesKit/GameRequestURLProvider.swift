/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

#if !os(tvOS)

@objcMembers
@objc(FBSDKGameRequestURLProvider)
public final class GameRequestURLProvider: NSObject {
  private enum URLValues {
    static let host = "fb.gg"
    static let path = "/game_requestui/"
  }

  @objc(createDeepLinkURLWithQueryDictionary:)
  public class func createDeepLinkURL(queryDictionary: [String: Any]) -> URL? {
    var components = URLComponents()
    components.scheme = URLScheme.https.rawValue
    components.host = URLValues.host
    components.path = "\(URLValues.path)\(AccessToken.current?.appID ?? "")"
    components.queryItems = Self.getQueryArray(from: queryDictionary)
    return components.url
  }

  @objc(filtersNameForFilters:)
  public class func filtersName(for filters: GameRequestFilter) -> String? {
    switch filters {
    case .appUsers:
      return "app_users"
    case .appNonUsers:
      return "app_non_users"
    case .everybody:
      let graphDomain = Utility.getGraphDomainFromToken()
      if graphDomain == "gaming",
         InternalUtility.shared.isFacebookAppInstalled {
        return "everybody"
      } else {
        return nil
      }
    default:
      return nil
    }
  }

  @objc(actionTypeNameForActionType:)
  public class func actionTypeName(for actionType: GameRequestActionType) -> String? {
    switch actionType {
    case .send: return "send"
    case .askFor: return "askfor"
    case .turn: return "turn"
    case .invite: return "invite"
    default: return nil
    }
  }

  private class func getQueryArray(from gameRequestDictionary: [String: Any]) -> [URLQueryItem] {
    gameRequestDictionary.compactMap { key, value in
      guard let value = value as? String else { return nil }

      return URLQueryItem(name: key, value: value)
    }
  }
}

#endif
