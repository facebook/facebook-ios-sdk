/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public struct TournamentConfig {

  /**
   Title of the tournament
   */
  public var title: String?

  /**
   Timestamp when the tournament ends.
   If the expiration is in the past, then the tournament is already finished and has expired.
   */
  public var endTime: TimeInterval?

  /**
   The type of score the tournament accepts and ranks. See enum `ScoreType`
   */
  public var scoreType: TournamentScoreType?

  /**
   The sort order of the scores for the tournament
   */
  public var sortOrder: TournamentSortOrder?

  /**
   Payload of the tournament
   */
  public var payload: String?

  /**
   The image associated with the tournament
   */
  public var image: UIImage?

  /// Creates a new tournament configuration with the given parameters. Passing the created tournament to the `ShareTournamentDialog.show(score:tournamentConfig:)` will share and create the tournament server side.
  ///
  /// - Parameter title: Text title for the tournament
  /// - Parameter endTime: A date representing the end time for the tournament. if not specified, the default is a week after creation date.
  /// - Parameter scoreType: A score tyoe for the formatting of the scores in the tournament leaderboard. See enum `TournamentScoreType`, if not specified, the default is `TournamentScoreType.numeric`.
  /// - Parameter sortOrder: A sort order for the ordering of which score is best in the tournament. See enum `TournamentSortOrder`, if not specified, the default is `TournamentSortOrder.descending`.
  /// - Parameter image: An image that will be associated with the tournament and included in any posts.
  /// - Parameter payload: Optional data to attach to the update. All game sessions launched from the update will be able to access this blob. Must be less than or equal to 1000 characters when stringified.
  ///
  public init(
    title: String? = nil,
    endTime: Date? = nil,
    scoreType: TournamentScoreType? = nil,
    sortOrder: TournamentSortOrder? = nil,
    image: UIImage? = nil,
    payload: String? = nil
  ) {
    self.title = title
    self.endTime = endTime?.timeIntervalSince1970
    self.scoreType = scoreType
    self.sortOrder = sortOrder
    self.image = image
    self.payload = payload
  }
}
