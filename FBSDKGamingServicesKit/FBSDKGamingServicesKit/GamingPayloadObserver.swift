/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
@objc(FBSDKGamingPayloadObserver)
public final class GamingPayloadObserver: NSObject {
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

  enum Keys: String, CaseIterable {
    case gamingPayload = "payload"
    case gamingPayloadGameRequestID = "game_request_id"
    case gamingPayloadContextTokenID = "context_token_id"
    case gamingPayloadTournamentID = "tournament_id"
  }

  private override init() {}

  public convenience init(delegate: GamingPayloadDelegate?) {
    self.init()
    self.delegate = delegate
    ApplicationDelegate.shared.addObserver(self)
  }

  private func parseURLForPayloadEntryData(appLinkUrl: AppLinkURL) -> [String: String]? {
    let expectedParameters = Keys.allCases.map { $0.rawValue }
    let urlParameters = appLinkUrl.appLinkExtras
    let recievedParameters = urlParameters?.filter { expectedParameters.contains($0.key) }
    let containsPayload = recievedParameters?[Keys.gamingPayload.rawValue] != nil

    if containsPayload, recievedParameters?.keys.count ?? 0 > 1 {
      return recievedParameters as? [String: String]
    }
    return [:]
  }

  private func handleDeeplinkURLIntoApp(appLinkUrl: AppLinkURL) -> Bool {
    guard
      let delegate = delegate,
      let gameEntryData = parseURLForPayloadEntryData(appLinkUrl: appLinkUrl),
      !gameEntryData.keys.isEmpty
    else {
      return false
    }
    let payload = GamingPayload(URL: appLinkUrl)

    if
      let gameRequestID = gameEntryData[Keys.gamingPayloadGameRequestID.rawValue],
      delegate.responds(to: #selector(GamingPayloadDelegate.parsedGameRequestURLContaining(_:gameRequestID:))) {
      delegate.parsedGameRequestURLContaining?(payload, gameRequestID: gameRequestID)
      return true
    }

    if
      let gameContextTokenID = gameEntryData[Keys.gamingPayloadContextTokenID.rawValue],
      delegate.responds(to: #selector(GamingPayloadDelegate.parsedGamingContextURLContaining(_:))) {
      GamingContext.current = GamingContext(identifier: gameContextTokenID, size: 0)
      delegate.parsedGamingContextURLContaining?(payload)
      return true
    }

    if
      let tournamentID = gameEntryData[Keys.gamingPayloadTournamentID.rawValue],
      delegate.responds(to: #selector(GamingPayloadDelegate.parsedTournamentURLContaining(_:tournamentID:)))
    {
      delegate.parsedTournamentURLContaining?(payload, tournamentID: tournamentID)
      return true
    }
    return false
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
    return handleDeeplinkURLIntoApp(appLinkUrl: sdkURL)
  }
}
