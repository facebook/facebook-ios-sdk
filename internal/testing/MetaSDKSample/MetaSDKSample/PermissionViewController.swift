/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import MetaLogin

class PermissionViewController: UITableViewController, UINavigationControllerDelegate {

  let permissionViewItems: [PermissionViewItem] = [
    PermissionViewItem(permission: Permission.userAvatar),
    PermissionViewItem(permission: Permission.publicProfile)
  ]

  var selectedPermissions = Set<Permission>()

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationController?.delegate = self
    updatePermissionViewItems()
    tableView.allowsMultipleSelection = true
  }

  private func updatePermissionViewItems() {
    if selectedPermissions.isEmpty {return}
    permissionViewItems.forEach {
      if selectedPermissions.contains($0.permission) {
        $0.isSelected = true
      }
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return permissionViewItems.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // swiftlint:disable:next force_cast
    let cell = tableView.dequeueReusableCell(withIdentifier: "permissionCell", for: indexPath) as! PermissionCell

    cell.permission = permissionViewItems[indexPath.row]
    if permissionViewItems[indexPath.row].isSelected {
      tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
    } else {
      tableView.deselectRow(at: indexPath, animated: false)
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    permissionViewItems[indexPath.row].isSelected = true
    selectedPermissions.insert(permissionViewItems[indexPath.row].permission)
  }

  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    permissionViewItems[indexPath.row].isSelected = false
    selectedPermissions.remove(permissionViewItems[indexPath.row].permission)
  }

  func navigationController(
    _ navigationController: UINavigationController,
    willShow viewController: UIViewController,
    animated: Bool
  ) {
    (viewController as? HomeViewController)?.selectedPermissions = selectedPermissions
  }
}
