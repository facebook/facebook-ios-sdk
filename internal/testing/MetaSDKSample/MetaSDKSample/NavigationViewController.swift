/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

class NavigationViewController: UINavigationController, UINavigationControllerDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()

    self.delegate = self
  }

  private func addRightBarButtonTo(viewController: UIViewController) {
    let rightBarButton = UIBarButtonItem.init(
      barButtonSystemItem: .bookmarks,
      target: self,
      action: #selector(showConsole)
    )
    viewController.navigationItem.rightBarButtonItem = rightBarButton
  }

  func navigationController(
    _ navigationController: UINavigationController,
    willShow viewController: UIViewController,
    animated: Bool
  ) {
    self.addRightBarButtonTo(viewController: viewController)
  }

  @objc func showConsole(sender: UIBarButtonItem) {
    self.performSegue(withIdentifier: "showConsole", sender: nil)
  }

}
