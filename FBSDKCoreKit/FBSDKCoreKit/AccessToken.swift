/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 AccessToken Extension
 */
public extension AccessToken {
  /**
   Returns the known granted permissions.
   */
  var permissions: Set<Permission> {
    Set(__permissions.map { Permission(stringLiteral: $0) })
  }

  /**
   Returns the known declined permissions.
   */
  var declinedPermissions: Set<Permission> {
    Set(__declinedPermissions.map { Permission(stringLiteral: $0) })
  }

  /**
   Returns the known expired permissions.
   */
  var expiredPermissions: Set<Permission> {
    Set(__expiredPermissions.map { Permission(stringLiteral: $0) })
  }

  /**
   Convenience getter to determine if a permission has been granted
   - parameter permission: The permission to check
   */
  func hasGranted(_ permission: Permission) -> Bool {
    hasGranted(permission: permission.name)
  }
}
