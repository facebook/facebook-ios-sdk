/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import FBSDKCoreKit_Basics

enum LoginUtility {
  static func stringForAudience(_ audience: DefaultAudience) -> String {
    switch audience {
    case .onlyMe:
      return "only_me"
    case .friends:
      return "friends"
    case .everyone:
      return "everyone"
    @unknown default:
      return ""
    }
  }

  static func getQueryParameters(from url: URL) -> [String: Any]? {
    let appURL = try? InternalUtility.shared.appURL(
      withHost: "authorize",
      path: "",
      queryParameters: [:]
    )

    if let prefix = appURL?.absoluteString,
       !url.absoluteString.hasPrefix(prefix),
       url.host != "authorize" { // Don't have an App ID, just verify path.
      return nil
    }
    var params = InternalUtility.shared.parameters(fromFBURL: url)
    if let userID = Self.getUserID(from: params["signed_request"] as? String) {
      params["user_id"] = userID
    }

    return params
  }

  static func getUserID(from signedRequest: String?) -> String? {
    guard let signedRequest = signedRequest else {
      return nil
    }
    let signatureAndPayload = signedRequest.components(separatedBy: ".")
    var userID: String?

    if signatureAndPayload.count == 2 {
      let payload = signatureAndPayload[1]
      if let data = Base64.decode(asData: payload),
         let dictionary = try? TypeUtility.jsonObject(with: data) as? [String: Any] {
        userID = dictionary["user_id"] as? String
      }
    }

    return userID
  }
}

#endif
