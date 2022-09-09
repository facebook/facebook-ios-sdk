/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import MetaLogin

class UserSessionViewController: UITableViewController {

  @IBOutlet weak var userIdLabel: UILabel!
  @IBOutlet weak var requestedPermissionsLabel: UILabel!
  @IBOutlet weak var graphDomainLabel: UILabel!
  @IBOutlet weak var userIDCopyButton: UIButton!

  @IBAction func onCopy(_ sender: Any) {
    UIPasteboard.general.string = userIdLabel.text
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    Task {
      await updateUserSession()
    }
  }

  func updateUserSession() async {
    if let userSession = await MetaLogin().userSession {
      userIdLabel.text = String(userSession.userID)
      requestedPermissionsLabel.text = userSession.requestedPermissions
        .map {$0.rawValue}
        .joined(separator: ", ")
      graphDomainLabel.text = userSession.graphDomain.rawValue
    }
  }

}
