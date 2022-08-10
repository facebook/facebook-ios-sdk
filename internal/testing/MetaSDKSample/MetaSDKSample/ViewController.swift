// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit
import MetaLogin

class ViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!

    @IBAction func onLoginClicked(_ sender: Any) {
        guard let configuration = LoginConfiguration(
            permissions: [.publicProfile],
            facebookAppID: "184484190795",
            metaAppID: "some_meta_app_id"
        ) else {
          return
        }

        MetaLogin().logIn(configuration: configuration) { result in
            switch result {
            case .success(let result):
                self.resultLabel.text = result
            case .failure(let error):
                self.resultLabel.text = error.localizedDescription
            }
        }
    }
}
