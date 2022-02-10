/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookLogin
import UIKit

final class LoginManagerViewController: LoginViewController {

    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var useLimitedLoginSwitch: UISwitch!
    @IBOutlet private weak var nonceTextField: UITextField!

    private var trackingPreference: LoginTracking {
        useLimitedLoginSwitch.isOn ? .limited : .enabled
    }

    private var nonce: String? {
        nonceTextField.text
    }

    private let loginManager = LoginManager()

    var configuration: LoginConfiguration? {
        if let nonce = nonce, !nonce.isEmpty {
            return LoginConfiguration(
                permissions: [.publicProfile, .email],
                tracking: trackingPreference,
                nonce: nonce
            )
        }
        else {
            return LoginConfiguration(
                permissions: [.publicProfile, .email],
                tracking: trackingPreference
            )
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateLoginButton()
    }

    @IBAction func toggleLoginState() {
        guard !isLoggedIn else {
            loginManager.logOut()
            return updateLoginButton()
        }

        invokeLoginMethod()
    }

    @IBAction func invokeLoginMethod() {
        guard let validConfiguration = configuration else {
            return presentAlert(
                title: "Invalid Configuration",
                message: "Please provide a valid login configuration"
            )
        }

        loginManager.logIn(
            viewController: self,
            configuration: validConfiguration
        ) { [unowned self] result in
            switch result {
            case .cancelled:
                self.presentAlert(
                    title: "Cancelled",
                    message: "Login attempt was cancelled"
                )
            case .failed(let error):
                self.presentAlert(for: error)
            case .success:
                self.updateLoginButton()
                self.showLoginDetails()
            }
        }
    }

    func updateLoginButton() {
        loginButton.setTitle(
            isLoggedIn ? "Log Out" : "Log In With Facebook",
            for: .normal
        )
    }

}
