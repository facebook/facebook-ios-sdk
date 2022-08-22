/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import MetaLogin

class AccessTokenViewController: UITableViewController {

  @IBOutlet weak var dataAccessExpirationDateLabel: UILabel!
  @IBOutlet weak var expirationDateLabel: UILabel!
  @IBOutlet weak var tokenStringLabel: UILabel!
  @IBOutlet weak var copyButton: UIButton!

  @IBAction func onClickAction(_ sender: Any) {
    UIPasteboard.general.string = tokenStringLabel.text
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    Task {
      await updateAccessToken()
    }
  }

  func updateAccessToken() async {
    if let accessToken =  await MetaLogin().userSession?.accessToken {
      print(accessToken.dataAccessExpirationDate)
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH:mm"
      tokenStringLabel.text = accessToken.tokenString
      expirationDateLabel.text = """
        \(accessToken.isExpired ? "Expired" :
        dateFormatter.string(from: accessToken.expirationDate))
        """
      dataAccessExpirationDateLabel.text = """
        \(accessToken.isDataAccessExpired ? "Expired":
        dateFormatter.string(from: accessToken.dataAccessExpirationDate))
        """
    }
  }
}
