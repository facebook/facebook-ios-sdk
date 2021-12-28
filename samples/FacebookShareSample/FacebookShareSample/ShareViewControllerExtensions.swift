/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
