/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/// The `TournamentSortOrder` is how the tournament score is ranked in the tournament.
public enum TournamentSortOrder: String {
  case higherIsBetter = "HIGHER_IS_BETTER"
  case lowerIsBetter = "LOWER_IS_BETTER"
}
