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

    private var buttonContainerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupButtonContainer()

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

    private func setupButtonContainer() {
        buttonContainerView = UIView()
        if #available(iOS 13.0, *) {
            buttonContainerView.backgroundColor = .systemBackground
        } else {
            buttonContainerView.backgroundColor = .white
        }
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainerView)

        let revokeButton = UIButton(type: .system)
        revokeButton.setTitle("Revoke Access Token", for: .normal)
        revokeButton.translatesAutoresizingMaskIntoConstraints = false
        revokeButton.addTarget(self, action: #selector(revokeAccessTokenTapped), for: .touchUpInside)
        buttonContainerView.addSubview(revokeButton)

        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("Refresh Token", for: .normal)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.addTarget(self, action: #selector(refreshTokenTapped), for: .touchUpInside)
        buttonContainerView.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            revokeButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 12),
            revokeButton.centerXAnchor.constraint(equalTo: buttonContainerView.centerXAnchor),

            refreshButton.topAnchor.constraint(equalTo: revokeButton.bottomAnchor, constant: 12),
            refreshButton.centerXAnchor.constraint(equalTo: buttonContainerView.centerXAnchor),
            refreshButton.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -12),
        ])
    }

    @objc private func revokeAccessTokenTapped() {
        guard AccessToken.current != nil else {
            showAlert(title: "Error", message: "No access token available. Please log in first.")
            return
        }
        executeRevokeRequest()
    }

    @objc private func refreshTokenTapped() {
        refreshAccessToken()
    }

    private func executeRevokeRequest() {
        guard let accessToken = AccessToken.current?.tokenString else {
            showAlert(title: "Error", message: "No access token available")
            return
        }

        let urlString = "https://graph.facebook.com/v17.0/me/permissions?access_token=\(accessToken)"
        guard let url = URL(string: urlString) else {
            showAlert(title: "Error", message: "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    self?.showAlert(
                        title: "Error (\(error.code))",
                        message: "\(error.localizedDescription)"
                    )
                    return
                }

                self?.showAlert(title: "Token Revoked", message: "All permissions have been revoked. Tap 'Refresh Token' to update the UI.")
            }
        }
        task.resume()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func refreshAccessToken() {
        guard let accessToken = AccessToken.current?.tokenString else {
            showAlert(title: "Error", message: "No access token available")
            return
        }

        let urlString = "https://graph.facebook.com/v17.0/me?fields=id,name,email&access_token=\(accessToken)"
        guard let url = URL(string: urlString) else {
            showAlert(title: "Error", message: "Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Network Error", message: error.localizedDescription)
                    return
                }

                guard let data = data else {
                    self?.showAlert(title: "Error", message: "No data received")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let errorInfo = json["error"] as? [String: Any] {
                            // Token is invalid/revoked
                            let message = errorInfo["message"] as? String ?? "Token is invalid"
                            AccessToken.current = nil
                            AuthenticationToken.current = nil
                            Profile.current = nil
                            self?.updateUIAfterRevocation()
                            self?.showAlert(title: "Token Invalid", message: message)
                        } else {
                            // Token is valid
                            self?.updateUIWithCurrentToken()
                            let name = json["name"] as? String ?? "Unknown"
                            self?.showAlert(title: "Token Valid", message: "Token is valid for user: \(name)")
                        }
                    }
                } catch {
                    self?.showAlert(title: "Parse Error", message: error.localizedDescription)
                }
            }
        }
        task.resume()
    }

    private func updateUIAfterRevocation() {
        accessTokenLabel.text = "REVOKED"
        permissionsLabel.text = "REVOKED"
        declinedPermissionsLabel.text = "REVOKED"
        authenticationTokenLabel.text = "REVOKED"
        nonceLabel.text = "REVOKED"
        nameLabel.text = Self.missingProfile
        userIdentifierLabel.text = Self.missingProfile
        emailLabel.text = "Email unavailable"
    }

    private func updateUIWithCurrentToken() {
        let accessToken = AccessToken.current
        let authenticationToken = AuthenticationToken.current
        let profile = Profile.current

        accessTokenLabel.text = accessToken?.tokenString ?? Self.missingAccessToken
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
