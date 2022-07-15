// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit
import MetaLogin

class ViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!

    @IBAction func onLoginClicked(_ sender: Any) {
        MetaLogin().logIn { result in
            switch result {
            case .success(let result):
                self.resultLabel.text = result
            case .failure(let error):
                self.resultLabel.text = error.localizedDescription
            }
        }
    }
}
