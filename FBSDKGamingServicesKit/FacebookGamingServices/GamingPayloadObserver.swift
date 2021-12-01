/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

let kGamingPayload = "payload"
let kGamingPayloadGameRequestID = "game_request_id"
let kGamingPayloadContextTokenID = "context_token_id"

@objcMembers
@objc(FBSDKGamingPayloadObserver)
public class GamingPayloadObserver: NSObject {
  public weak var delegate: GamingPayloadDelegate? {
    willSet {
      if let sharedInstance = GamingPayloadObserver.shared {
        if newValue == nil {
          ApplicationDelegate.shared.removeObserver(sharedInstance)
          GamingPayloadObserver.shared = nil
        }

        if delegate == nil { // i.e. oldValue
          ApplicationDelegate.shared.addObserver(sharedInstance)
        }
      }
    }
  }

  private static var shared: GamingPayloadObserver? = GamingPayloadObserver()

  private override init() { }

  public convenience init(delegate: GamingPayloadDelegate?) {
    self.init()
    self.delegate = delegate
    ApplicationDelegate.shared.addObserver(self)
  }
}

extension GamingPayloadObserver: FBSDKApplicationObserving {
  public func application(
    _ application: UIApplication,
    open url: URL,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    let sdkURL = AppLinkURL(url: url)
    let urlContainsGamingPayload = sdkURL.appLinkExtras?[kGamingPayload] != nil

    let gameRequestID = sdkURL.appLinkExtras?[kGamingPayloadGameRequestID] as? String
    let urlContainsGameRequestID = gameRequestID != nil

    let gameContextTokenID = sdkURL.appLinkExtras?[kGamingPayloadContextTokenID] as? String
    let urlContainsGameContextTokenID = gameContextTokenID != nil

    if !urlContainsGamingPayload || (urlContainsGameContextTokenID && urlContainsGameRequestID) {
      return false
    }

    guard let delegate = delegate else { return false }

    let payload = GamingPayload(URL: sdkURL)

    if let gameRequestID = gameRequestID, // swiftlint:disable:next indentation_width
       delegate.responds(to: #selector(GamingPayloadDelegate.parsedGameRequestURLContaining(_:gameRequestID:))) {
      delegate.parsedGameRequestURLContaining?(payload, gameRequestID: gameRequestID)
      return true
    }

    if let gameContextTokenID = gameContextTokenID, // swiftlint:disable:next indentation_width
       delegate.responds(to: #selector(GamingPayloadDelegate.parsedGamingContextURLContaining(_:))) {
      GamingContext.current = GamingContext(identifier: gameContextTokenID, size: 0)
      delegate.parsedGamingContextURLContaining?(payload)
      return true
    }
    return false
  }
}
