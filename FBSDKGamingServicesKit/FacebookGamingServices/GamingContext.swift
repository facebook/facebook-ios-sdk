/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
@objc(FBSDKGamingContext)
public final class GamingContext: NSObject {

  /**
   A shared object that holds data about the current user's game instance which could be solo game or multiplayer game with other users.
   */
  @objc(currentContext) public static var current: GamingContext?

  /**
   A unique identifier for the current game context. This represents a specific game instance that the user is playing in.
   */
  public let identifier: String

  /**
   The number of players in the current user's game instance
   */
  public let size: Int

  public init?(identifier: String, size: Int) {
    guard !identifier.isEmpty else { return nil }

    self.identifier = identifier
    self.size = max(0, size)

    super.init()
    Self.current = self
  }
}
