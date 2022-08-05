/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum RawLoginParameters {
    enum Keys {
        static let accessToken = "access_token"
        static let grantedScopes = "granted_scopes"
        static let deniedScopes = "denied_scopes"
        static let signedRequest = "signed_request"
        static let expires = "expires"
        static let expiresAt = "expires_at"
        static let expiresIn = "expires_in"
        static let dataAccessExpirationTime = "data_access_expiration_time"
        static let graphDomain = "graph_domain"
    }

    static let accessToken = "some_access_token"
    static let grantedScopes = "foo,bar"
    static let deniedScopes = "email"
    static let requestedPermissions = ["foo", "bar"]
    static let declinedPermissions = ["email"]
    static let signedRequest = "some_signed_request"
    static let expires = "1666808603.0"
    static let expiresDate = Date(timeIntervalSince1970: 1666808603.0)
    static let expiresAt = "1666808660.0"
    static let expiresAtDate = Date(timeIntervalSince1970: 1666808660.0)
    static let expiresIn = "5790.0"
    static let expiresInDate = Date(timeIntervalSinceNow: 5790.0)
    static let dataAccessExpirationTime = "1666808603.0"
    static let dataAccessExpirationDate = Date(timeIntervalSince1970: 1666808603.0)
    static let graphDomain = "facebook"

    static var withDefaultParameters: [String: Any] = [
        Keys.accessToken: accessToken,
        Keys.grantedScopes: grantedScopes,
        Keys.deniedScopes: deniedScopes,
        Keys.signedRequest: signedRequest,
        Keys.expires: expires,
        Keys.expiresAt: expiresAt,
        Keys.expiresIn: expiresIn,
        Keys.dataAccessExpirationTime: dataAccessExpirationTime,
        Keys.graphDomain: graphDomain
    ]

    static var withNoExpiresParameter: [String: Any] {
        filterParameters(withKeys: [Keys.expires])
    }

    static var withNoExpiresAndExpiresAtParameters: [String: Any] {
        filterParameters(withKeys: [Keys.expires, Keys.expiresAt])
    }

    static var withNoExpirationParameters: [String: Any] {
        filterParameters(withKeys: [Keys.expires, Keys.expiresIn, Keys.expiresAt])
    }

    static var withEmptyPermissions: [String: Any] {
        var parameters = withDefaultParameters
        parameters[Keys.deniedScopes] = []
        return parameters
    }

    static var withNoAccessToken: [String: Any] {
        filterParameters(withKeys: [Keys.accessToken])
    }

    private static func filterParameters(withKeys keys: [String]) -> [String: Any] {
        let parameters = withDefaultParameters.filter { !keys.contains($0.0) }
        return parameters
    }
}
