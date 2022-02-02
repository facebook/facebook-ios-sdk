/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKGamingPayloadDelegate)
public protocol GamingPayloadDelegate: NSObjectProtocol {
  /**
   Delegate method will be triggered when a `GamingPayloadObserver` parses a url with a payload and game request ID
   @param payload The payload recieved in the url
   @param gameRequestID The game request ID recieved in the url
   */
  @objc optional func parsedGameRequestURLContaining(_ payload: GamingPayload, gameRequestID: String)

  /**
   Delegate method will be triggered when a `GamingPayloadObserver` parses a gaming context url with a payload and game context token ID. The current gaming context will be update with the context ID.
   @param payload The payload recieved in the url
   */
  @objc optional func parsedGamingContextURLContaining(_ payload: GamingPayload)

  /**
   Delegate method will be triggered when a `GamingPayloadObserver` parses a url with a payload and tournament ID
   @param payload The payload associated with the tournament
   @param tournamentID The tournament ID the player wants to enter
   */
  @objc optional func parsedTournamentURLContaining(_ payload: GamingPayload, tournamentID: String)
}
