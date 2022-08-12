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
    @IBOutlet weak var appTitle: UINavigationItem!

    var cellTitles: [String] = ["User Session"]
    let metaLogin = MetaLogin()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func onLoginClicked(_ sender: Any) {
        guard let configuration = LoginConfiguration(
            permissions: ["public_profile"],
            facebookAppID: "184484190795",
            metaAppID: "some_meta_app_id"
        ) else {
            return
        }

        metaLogin.logIn(configuration: configuration) { result in
            switch result {
            case .success:
                print("Successful login")
            case .failure(let error):
                print("Failed to login with \(error)")
            }
        }
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "loginDetailCell", for: indexPath) as! LoginDetailCell
        cell.textLabel?.text = cellTitles[indexPath.row]
        if indexPath.row == 0 {
            cell.selectionStyle = .blue
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            performSegue(withIdentifier: "showUserSession", sender: self)
        }
    }
}
