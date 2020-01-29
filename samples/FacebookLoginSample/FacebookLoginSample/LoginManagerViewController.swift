// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FacebookLogin
import UIKit

class LoginManagerViewController: LoginViewController {

    @IBOutlet private weak var loginButton: UIButton!

    var isLoggedIn: Bool {
        guard let token = AccessToken.current else { return false }
        
        return !token.isExpired
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateLoginButton()
    }

    @IBAction func toggleLoginState() {
        let loginManager = LoginManager()

        guard !isLoggedIn else {
            loginManager.logOut()
            return updateLoginButton()
        }

        loginManager.logIn(
            permissions: [.publicProfile, .email],
            viewController: self
        ) { [unowned self] result in

            switch result {
            case .failed(let error):
                self.presentAlert(for: error)
            
            case .cancelled:
                self.presentAlert(title: "Cancelled", message: "Login attempt was cancelled")
            
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
