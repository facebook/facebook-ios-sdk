/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
@objc(FBSDKGamingContext)
public class GamingContext: NSObject {

  /**
   A shared object that holds data about the current user's game instance which could be solo game or multiplayer game with other users.
   */
  @objc(currentContext) public static var current: GamingContext?

  /**
   A unique identifier for the current game context. This represents a specific game instance that the user is playing in.
   */
  public private(set) var identifier: String

  /**
   The number of players in the current user's game instance
   */
  public private(set) var size: Int = 0

  private init?(identifier: String, size: Int) {
    if identifier.isEmpty {
      return nil
    }

    self.identifier = identifier
    if size > 0 {
      self.size = size
    }
    super.init()
    Self.current = self
  }

  /**
   Internal Type exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   Creates a context with an identifier. If the identifier is nil or empty, a context will not be created.

   @warning INTERNAL - DO NOT USE
   */

  @discardableResult
  public static func createContext(withIdentifier identifier: String, size: Int) -> Self? {
    GamingContext(identifier: identifier, size: size) as? Self
  }
}
