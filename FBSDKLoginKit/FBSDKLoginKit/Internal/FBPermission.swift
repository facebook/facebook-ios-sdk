/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics

#if !os(tvOS)

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 - Warning INTERNAL:  DO NOT USE
 */
@objcMembers
@objc(FBSDKPermission)
public final class FBPermission: NSObject {

  /// The raw string representation of the permission
  let value: String
  public override var description: String {
    value
  }
  public override var hash: Int {
    value.hash
  }

  /**
   Attempts to initialize a new permission with the given string.
   Creation will fail and return nil if the string is invalid.
   - Parameter string: The raw permission string
   */
  public init?(string: String) {
    let allowedCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz_")
    guard !string.isEmpty,
          allowedCharacterSet.isSuperset(of: CharacterSet(charactersIn: string))
    else { return nil }
    value = string
  }

  /**
   Returns a set of `FBPermission` from a set of raw permissions strings.
   Will return nil if any of the input permissions is invalid.
   */
  @objc(permissionsFromRawPermissions:)
  public static func permissions(fromRawPermissions rawPermissions: Set<String>) -> Set<FBPermission>? {
    var permissions = Set<FBPermission>()
    for rawPermission in rawPermissions {
      guard let permission = FBPermission(string: rawPermission) else { return nil }

      permissions.insert(permission)
    }
    return permissions
  }

  /**
   Returns a set of string permissions from a set of `FBPermission` by
   extracting the "value" property for each element.
   */
  @objc(rawPermissionsFromPermissions:)
  public static func rawPermissions(from permissions: Set<FBPermission>) -> Set<String> {
    Set(permissions.map(\.value))
  }

  public override func isEqual(_ object: Any?) -> Bool {
    (object as? FBPermission)?.value == value
  }
}

#endif
