// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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

import FacebookShare
import UIKit

extension ShareViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let appID = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String,
            appID != "{your-app-id}"
            else {
                return presentAlert(
                    title: "Invalid App Identifier",
                    message: "Please enter your Facebook application identifier in your Info.plist. This can be found on the developer portal at developers.facebook.com"
                )
        }

        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: [String]]],
            let scheme = urlTypes.first?["CFBundleURLSchemes"]?.first,
            scheme != "fb{your-app-id}"
            else {
                return presentAlert(
                    title: "Invalid URL Scheme",
                    message: "Please update the url scheme in your info.plist with your Facebook application identifier to allow for the login flow to reopen this app"
                )
        }
    }

    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default)
        alertController.addAction(dismissAction)

        present(alertController, animated: true)
    }

    func presentAlert(for error: Error) {
        let nsError = error as NSError

        guard let sdkMessage = nsError.userInfo["com.facebook.sdk:FBSDKErrorDeveloperMessageKey"] as? String
            else {
                preconditionFailure("Errors from the SDK should have a developer facing message")
        }

        presentAlert(title: "Sharing Error", message: sdkMessage)
    }

}
