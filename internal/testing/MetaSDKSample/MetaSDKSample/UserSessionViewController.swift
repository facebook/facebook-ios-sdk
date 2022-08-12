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
  @IBOutlet weak var declinedPermissionsLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    updateUserSession()
  }

  func updateUserSession() {
    if let userSession = MetaLogin().userSession {
      userIdLabel.text = String(userSession.userID)
      requestedPermissionsLabel.text = userSession.requestedPermissions
        .map {$0.rawValue}
        .joined(separator: ", ")
      graphDomainLabel.text = userSession.graphDomain.rawValue
      declinedPermissionsLabel.text = userSession.declinedPermissions
        .map {$0.rawValue}
        .joined(separator: ", ")
    }
  }

}
