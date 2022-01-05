/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/**
 A model for an instant games createAsync cross play request.
 */
@objcMembers
@objc(FBSDKCreateContextContent)
public class CreateContextContent: NSObject, ValidatableProtocol {

  /**
   The ID of the player that is being challenged.
   @return The ID for the player being challenged
   */
  public var playerID: String

  /**
   Builds a content object that will be use to display a create context dialog
   @param playerID The player ID of the user being challenged which will be used  to create a game context
   */
  @objc(initDialogContentWithPlayerID:)
  public init(playerID: String) {
    self.playerID = playerID
  }

  public override func isEqual(_ object: Any?) -> Bool {
    let contentObject = (object as? CreateContextContent)
    return playerID == contentObject?.playerID
  }

  // MARK: - SharingValidation

  public func validate() throws {
    let hasPlayerID = !playerID.isEmpty
    guard hasPlayerID else {
      throw ErrorFactory().requiredArgumentError(
        name: "playerID",
        message: "The playerID is required.",
        underlyingError: nil
      )
    }
  }
}

#endif
