/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

class PermissionCell: UITableViewCell {

  @IBOutlet weak var titleLable: UILabel!

  var permission: PermissionViewItem? {
    didSet {
      titleLable.text = permission?.title
    }
  }

  override func awakeFromNib() {
     super.awakeFromNib()

     selectionStyle = .none
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    accessoryType = selected ? .checkmark: .none
  }

}
