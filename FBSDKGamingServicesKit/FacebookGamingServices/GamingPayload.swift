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

  public var payload: String {
    URL.appLinkExtras?[kGamingPayload] as? String ?? ""
  }

  var gameRequestID: String {
    URL.appLinkExtras?[kGamingPayloadGameRequestID] as? String ?? ""
  }

  public init(URL: AppLinkURL) {
    self.URL = URL
  }
}
