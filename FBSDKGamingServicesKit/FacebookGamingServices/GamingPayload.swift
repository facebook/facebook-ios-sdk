/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
@objc(FBSDKGamingPayload)
public class GamingPayload: NSObject {

  public var URL: AppLinkURL
  var gameEntryData: [String: String] = [:]

  public var payload: String

  var gameRequestID: String {
    gameEntryData[GamingPayloadObserver.Keys.gamingPayloadGameRequestID.rawValue] ?? ""
  }

  public init(URL: AppLinkURL) {
    self.URL = URL
    let requestID = URL.appLinkExtras?[GamingPayloadObserver.Keys.gamingPayloadGameRequestID.rawValue]  as? String ?? ""
    payload = URL.appLinkExtras?[GamingPayloadObserver.Keys.gamingPayload.rawValue] as? String ?? ""

    gameEntryData[GamingPayloadObserver.Keys.gamingPayload.rawValue] = payload
    gameEntryData[GamingPayloadObserver.Keys.gamingPayloadGameRequestID.rawValue] = requestID
  }
}
