/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookLogin
import UIKit

class LoginButtonViewController: LoginViewController {

    @IBOutlet private weak var loginButton: FBLoginButton!
    @IBOutlet private weak var useLimitedLoginSwitch: UISwitch!
    @IBOutlet private weak var nonceTextField: UITextField!

    var loginTracking: LoginTracking {
        useLimitedLoginSwitch.isOn ? .limited : .enabled
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loginButton.loginTracking = loginTracking
        loginButton.delegate = self
    }

}

extension LoginButtonViewController: LoginButtonDelegate {

    func loginButtonWillLogin(_ loginButton: FBLoginButton) -> Bool {
        loginButton.loginTracking = loginTracking

        if let nonce = nonceTextField?.text, !nonce.isEmpty {
            loginButton.nonce = nonce
        }

        return true
    }

    func loginButton(
        _ loginButton: FBLoginButton,
        didCompleteWith potentialResult: LoginManagerLoginResult?,
        error potentialError: Error?
    ) {
        if let error = potentialError {
            return presentAlert(for: error)
        }

        guard let result = potentialResult else {
            return presentAlert(
                title: "Invalid Result",
                message: "Login attempt failed"
            )
        }

        guard !result.isCancelled else {
            return presentAlert(
                title: "Cancelled",
                message: "Login attempt was cancelled"
            )
        }

        showLoginDetails()
    }

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        presentAlert(title: "Logged Out", message: "You are now logged out.")
    }

}
