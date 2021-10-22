/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/// The `TournamentSortOrder` is how the tournament `score` is ranked in the tournament.
enum TournamentSortOrder: String {
  case descending = "HIGHER_IS_BETTER"
  case ascending = "LOWER_IS_BETTER"
}
