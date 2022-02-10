/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookCore
import FacebookLogin
import UIKit

final class LoginDetailsViewController: UIViewController {

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
