/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import Foundation

@objc(FBSDKChooseContextFilter)
public enum ChooseContextFilter: Int, CaseIterable {
  case none
  case existingChallenges
  case newPlayersOnly
  case newContextOnly

  public var name: String {
    switch self {
    case .none:
      return "NO_FILTER"
    case .existingChallenges:
      return "INCLUDE_EXISTING_CHALLENGES"
    case .newPlayersOnly:
      return "NEW_PLAYERS_ONLY"
    case .newContextOnly:
      return "NEW_CONTEXT_ONLY"
    }
  }
}

/// A model for an instant games choose context app switch dialog
@objcMembers
@objc(FBSDKChooseContextContent)
public final class ChooseContextContent: NSObject, ValidatableProtocol {

  /// This sets the filter which determines which context will show when the user is app switched to the choose context dialog.
  public var filter = ChooseContextFilter.none

  /// This sets the maximum number of participants that the suggested context(s) shown in the dialog should have.
  public var maxParticipants = 0

  /// This sets the minimum number of participants that the suggested context(s) shown in the dialog should have.
  public var minParticipants = 0

  public static func filtersName(forFilters filter: ChooseContextFilter) -> String {
    switch filter {
    case .newContextOnly:
      return "NEW_CONTEXT_ONLY"
    case .existingChallenges:
      return "INCLUDE_EXISTING_CHALLENGES"
    case .newPlayersOnly:
      return "NEW_PLAYERS_ONLY"
    case .none:
      return "NO_FILTER"
    }
  }

  // MARK: - ValidatableProtocol

  public func validate() throws {
    if minParticipants == 0, maxParticipants == 0 {
      return
    }

    let minimumGreaterThanMaximum = minParticipants > maxParticipants
    if minimumGreaterThanMaximum, maxParticipants != 0 {
      let message = "The minimum size cannot be greater than the maximum size"
      throw ErrorFactory().requiredArgumentError(
        name: "minParticipants",
        message: message,
        underlyingError: nil
      )
    }
  }

  // MARK: - NSObject

  public override func isEqual(_ object: Any?) -> Bool {
    let contentObject = (object as? ChooseContextContent)
    return filter.rawValue == contentObject?.filter.rawValue
      && minParticipants == contentObject?.minParticipants
      && maxParticipants == contentObject?.maxParticipants
  }
}

#endif
