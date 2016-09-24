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

import Foundation
import UIKit

import FacebookCore
import FacebookLogin

class LoginManagerViewController: UIViewController {

  func loginManagerDidComplete(_ result: LoginResult) {
    let alertController: UIAlertController
    switch result {
    case .cancelled:
      alertController = UIAlertController(title: "Login Cancelled", message: "User cancelled login.")
    case .failed(let error):
      alertController = UIAlertController(title: "Login Fail", message: "Login failed with error \(error)")
    case .success(let grantedPermissions, _, _):
      alertController = UIAlertController(title: "Login Success",
                                          message: "Login succeeded with granted permissions: \(grantedPermissions)")
    }
    self.present(alertController, animated: true, completion: nil)
  }
}

extension LoginManagerViewController {

  @IBAction func loginWithReadPermissions() {
    let loginManager = LoginManager()
    loginManager.logIn([.publicProfile, .userFriends], viewController: self) { result in
      self.loginManagerDidComplete(result)
    }
  }

  @IBAction func loginWithPublishPermissions() {
    let loginManager = LoginManager()
    loginManager.logIn([.publishActions], viewController: self) { result in
      self.loginManagerDidComplete(result)
    }
  }

  @IBAction func logOut() {
    let loginManager = LoginManager()
    loginManager.logOut()

    let alertController = UIAlertController(title: "Logout", message: "Logged out.")
    present(alertController, animated: true, completion: nil)
  }
}
