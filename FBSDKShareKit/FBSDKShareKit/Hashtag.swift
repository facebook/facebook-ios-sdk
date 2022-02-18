/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Represents a single hashtag that can be used with the share dialog.
@objcMembers
@objc(FBSDKHashtag)
public final class Hashtag: NSObject {
  /**
   The hashtag string.
   You are responsible for making sure that `stringRepresentation` is a valid hashtag (a single '#' followed by one or more
   word characters). Invalid hashtags are ignored when sharing content. You can check validity with the`valid` property.
   @return The hashtag string
   */
  public var stringRepresentation: String

  @objc(initWithString:)
  public init(_ string: String) {
    stringRepresentation = string
  }

  public override var description: String {
    if isValid {
      return stringRepresentation
    } else {
      return "Invalid hashtag '\(stringRepresentation)'"
    }
  }

  /**
   Tests if a hashtag is valid.
   A valid hashtag matches the regular expression "#\w+": A single '#' followed by one or more word characters.
   @return true if the hashtag is valid, false otherwise.
   */
  public var isValid: Bool {
    stringRepresentation.range(of: "^#\\w+$", options: .regularExpression) != nil
  }

  // MARK: - Equality

  public override var hash: Int {
    stringRepresentation.hash
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? Hashtag else { return false }

    return stringRepresentation == other.stringRepresentation
  }
}
