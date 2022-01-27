/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

#if !os(tvOS)

/// Additional context about the nature of the game request.
@objc(FBSDKGameRequestActionType)
public enum GameRequestActionType: UInt {
  /// No action type
  case none

  /// Send action type: The user is sending an object to the friends.
  case send

  /// Ask For action type: The user is asking for an object from friends.
  case askFor

  /// Turn action type: It is the turn of the friends to play against the user in a match.
  case turn

  /// Invite action type: The user is inviting a friend.
  case invite
}

#endif
