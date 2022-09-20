/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import MetaLogin

class HomeViewController: UIViewController, PermissionSelectedDelegate, ConsoleDataProviding {

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var appTitle: UINavigationItem!
  @IBOutlet weak var editPermissionsButton: UIButton!

  let metaLogin = MetaLogin()
  let loginButtonLabel = "Login"
  let logoutButtonLabel = "Logout"

  var selectedPermissions: Set<Permission> = [.userAvatar]
  var isLoggedIn: Bool {
    get async {
      return await metaLogin.userSession != nil
    }
  }

  var cellConfigs: [LoginCellConfig] {[
    LoginCellConfig(
      cellTitle: "FB App ID:",
      cellValue: LoginConfiguration().facebookAppID,
      cellSelectionStyle: .none,
      cellAccessoryType: .none,
      activity: {}
    ),
    LoginCellConfig(
      cellTitle: "Meta App ID:",
      cellValue: LoginConfiguration().metaAppID,
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

    Task {
      await updateLoginButtons()
    }
  }

  func permissionWasSelected(_ selectedPermission: Set<Permission>) {
    self.selectedPermissions = selectedPermission
  }

  @IBAction func loginButtonTapped(_ sender: Any) {
    Task {
      if await isLoggedIn {
        await metaLogin.logOut()
        await self.updateLoginButtons()
        self.consoleDataManager.addMessage(message: "User logged out")
      } else {
        await login()
      }
    }
  }

  @IBAction func editPermissionsButtonTapped(_ sender: Any) {
    Task {
      await login()
    }
  }

  func login() async {
    self.consoleDataManager.addMessage(message: "Started login request")
    let configuration = LoginConfiguration(
      permissions: selectedPermissions
    )

    do {
      try await metaLogin.logIn(configuration: configuration)
      await self.updateLoginButtons()
      self.consoleDataManager.addMessage(message: "Login request completed")
    } catch let loginFailure as LoginFailure {
      switch loginFailure {
      case .isCanceled:
        self.consoleDataManager.addMessage(message: "Login cancelled")
      default:
        self.consoleDataManager.addMessage(message: "Failed to login with \(loginFailure)")
      }
    } catch {
      self.consoleDataManager.addMessage(message: "Unknown Error")
    }
  }

  private func updateLoginButtons() async {
    if await isLoggedIn {
      loginButton.setTitle(logoutButtonLabel, for: .normal)
      editPermissionsButton.isHidden = false
    } else {
      loginButton.setTitle(loginButtonLabel, for: .normal)
      editPermissionsButton.isHidden = true
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
        destination.delegate = self
        destination.selectedPermissions = selectedPermissions
      }
    }
  }
}
