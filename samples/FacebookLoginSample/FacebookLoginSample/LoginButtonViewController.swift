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

class LoginButtonViewController: LoginViewController {

    @IBOutlet private weak var loginButton: FBLoginButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        loginButton.delegate = self
    }

}

extension LoginButtonViewController: LoginButtonDelegate {

    func loginButton(
        _ loginButton: FBLoginButton,
        didCompleteWith potentialResult: LoginManagerLoginResult?,
        error potentialError: Error?
    ) {
        if let error = potentialError {
            return presentAlert(for: error)
        }

        guard let result = potentialResult else {
            return presentAlert(title: "Invalid Result", message: "Login attempt failed")
        }
        
        guard !result.isCancelled else {
            return presentAlert(title: "Cancelled", message: "Login attempt was cancelled")
        }

        showLoginDetails()
    }

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        presentAlert(title: "Logged Out", message: "You are now logged out.")
    }

}
