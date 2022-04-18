/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 An internal representation of tournament graph objects. Use `Tournament` instead.
 - Warning: For internal use only! Subject to change or removal at any time.
 */
@objcMembers
public final class _FBSDKTournament: NSObject {

  /// The unique ID that is associated with this tournament.
  public internal(set) var identifier: String

  /**
   Timestamp when the tournament ends.
   If the expiration is in the past, then the tournament is already finished and has expired.
   */
  public internal(set) var endTime: Date?

  /// Title of the tournament provided upon the creation of the tournament.
  public internal(set) var title: String?

  /// Payload of the tournament provided upon the creation of the tournament.
  public var payload: String?

  convenience init(tournament: Tournament) {
    self.init(
      identifier: tournament.identifier,
      endTime: tournament.endTime,
      title: tournament.title,
      payload: tournament.payload
    )
  }

  init(
    identifier: String,
    endTime: Date? = nil,
    title: String? = nil,
    payload: String? = nil
  ) {
    self.identifier = identifier
    self.endTime = endTime
    self.title = title
    self.payload = payload
  }
}
