/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import MetaLogin

class PermissionViewItem: Codable {
  let permission: Permission

  var isSelected = false

  var title: String {
    return permission.rawValue
  }

  init(permission: Permission) {
    self.permission = permission
  }
}
