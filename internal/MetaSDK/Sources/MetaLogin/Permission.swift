/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 A value representing a Graph API permission.

 Each permission has its own set of requirements and suggested use cases. Permission strings must contain only lowercase
 letters and underscores. Only valid permissions supported by Graph API will be used for authorization.
 */
public struct Permission: RawRepresentable, Hashable, Codable {
  public typealias RawValue = String

  /// The permission's string value.
  public let rawValue: String

  /// Creates a new instance with the given raw value.
  public init?(rawValue: String) {
    guard
      !rawValue.isEmpty,
      rawValue.rangeOfCharacter(from: Self.invalidCharacters) == nil
    else { return nil }

    self.rawValue = rawValue
  }

  private static var invalidCharacters: CharacterSet {
    CharacterSet(charactersIn: "\u{0061}" ... "\u{007A}")
      .union(CharacterSet(charactersIn: "_"))
      .inverted
  }

  // swiftlint:disable force_unwrapping

  /// Provides access to a user's avatar.
  public static let userAvatar = Self(rawValue: "user_avatar")!

  // swiftlint:enable force_unwrapping
}
