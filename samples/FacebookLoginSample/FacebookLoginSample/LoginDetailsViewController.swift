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

import FacebookCore
import FacebookLogin
import UIKit

class LoginDetailsViewController: UIViewController {

    @IBOutlet private weak var accessTokenLabel: UILabel!
    @IBOutlet private weak var permissionsLabel: UILabel!
    @IBOutlet private weak var declinedPermissionsLabel: UILabel!
    @IBOutlet private weak var authenticationTokenLabel: UILabel!
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var userIdentifierLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!

    private static let missingProfile = "Current Profile unavailable"
    private static let missingAccessToken = "Access Token Unavailable"

    override func viewDidLoad() {
        super.viewDidLoad()

        let accessToken = AccessToken.current
        let authenticationToken = AuthenticationToken.current
        let profile = Profile.current

        accessTokenLabel.text = accessToken?.tokenString
            ?? Self.missingAccessToken
        permissionsLabel.text = accessToken?.permissions
            .map { $0.name }
            .joined(separator: ", ")
            ?? Self.missingAccessToken
        declinedPermissionsLabel.text = accessToken?.declinedPermissions
            .map { $0.name }
            .joined(separator: ", ")
            ?? Self.missingAccessToken
        authenticationTokenLabel.text = authenticationToken?.tokenString
            ?? "Authentication Token Unavailable"
        nonceLabel.text = authenticationToken?.nonce
            ?? "Authentication Token Nonce Unavailable"
        nameLabel.text = profile?.name ?? Self.missingProfile
        userIdentifierLabel.text = profile?.userID ?? Self.missingProfile
        emailLabel.text = profile?.email ?? "Email unavailable"
    }

}
