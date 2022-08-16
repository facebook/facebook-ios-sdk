/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

struct LoginCellConfig {
  let cellTitle: String
  let cellValue: String?
  let cellSelectionStyle: UITableViewCell.SelectionStyle
  let cellAccessoryType: UITableViewCell.AccessoryType
  let activity: (() -> Void)?
}
