/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import MetaLogin

class HomeViewController: UIViewController {

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var appTitle: UINavigationItem!

  let metaLogin = MetaLogin()
  let loginButtonLabel = "Login"
  let logoutButtonLabel = "Logout"
  let appId = "184484190795"

  var selectedPermissions: Set<Permission> = [.publicProfile]
  var isLoggedIn: Bool {
    return metaLogin.userSession != nil
  }
  var cellConfigs: [LoginCellConfig] {[
    LoginCellConfig(
      cellTitle: "App ID:",
      cellValue: appId,
      cellSelectionStyle: .none,
      cellAccessoryType: .none,
      activity: {}
    ),
    LoginCellConfig(
      cellTitle: "User Session",
      cellValue: nil,
      cellSelectionStyle: .blue,
      cellAccessoryType: .disclosureIndicator,
      activity: {
        self.performSegue(withIdentifier: "showUserSession", sender: self)
      }
    ),
    LoginCellConfig(
      cellTitle: "Permission Setting",
      cellValue: nil,
      cellSelectionStyle: .blue,
      cellAccessoryType: .disclosureIndicator,
      activity: {
        self.performSegue(withIdentifier: "showPermissionSetting", sender: self)
      }
    )
  ]}

  override func viewDidLoad() {
    super.viewDidLoad()

    updateLoginButtonLabel()
  }

  @IBAction func loginButtonTapped(_ sender: Any) {
    if isLoggedIn {
      metaLogin.logOut()
      self.updateLoginButtonLabel()
    } else {
      guard let configuration = LoginConfiguration(
        permissions: selectedPermissions,
        facebookAppID: appId,
        metaAppID: "some_meta_app_id"
      ) else {
        return
      }

      metaLogin.logIn(configuration: configuration) { result in
        switch result {
        case .success:
          self.updateLoginButtonLabel()
        case .failure(let error):
          print("Failed to login with \(error)")
        case .cancel:
          print("Login cancelled")
        }

      }
    }
  }

  private func updateLoginButtonLabel() {
    if isLoggedIn {
      loginButton.setTitle(logoutButtonLabel, for: .normal)
    } else {
      loginButton.setTitle(loginButtonLabel, for: .normal)
    }
  }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cellConfigs.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // swiftlint:disable:next force_cast
    let cell = tableView.dequeueReusableCell(withIdentifier: "loginDetailCell", for: indexPath) as! HomeCell

    let cellConfig = self.cellConfigs[indexPath.row]
    cell.cellTitleLabel.text = cellConfig.cellTitle
    cell.accessoryType = cellConfig.cellAccessoryType
    cell.selectionStyle = cellConfig.cellSelectionStyle
    cell.cellValueLabel.text = cellConfig.cellValue
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellConfig = self.cellConfigs[indexPath.row]
    if let activity = cellConfig.activity {
      activity()
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showPermissionSetting" {
      if let destination = segue.destination as? PermissionViewController {
        destination.selectedPermissions = selectedPermissions
      }
    }
  }
}
