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
    static let signedRequest = "UTFN7nkkmnyhMtebvQs7P0B7TbMj567hKKzxPnQ2TNc.eyJ1c2VyX2lkIjoiMTExIiwiY29kZSI6IkFRQmU4dXZJbjdJeld0N29jb3lSWFhzN0RpX25LaFdpSGdweXZMbmtJTmhQMWV3V0FRWjdVX3lVdEVBQzBKSkY1by1ZU2cxY0tQX3A2dTJBRWZsM0o2VnpmazU5NXV0Zm5MRGFLTnk0Yl9DUzFkX0JhWTZXSHRYYVBRTk95WFRrQnk1MzlqZEcwblh1VXVCX3pNWXFBRWJPb3BnLWxiajJFS205QXgtS3IxQ1ZMSmx2SVpnTHpMLXVMaVNuell3X2NoeWNuZmJhQ2w1ZjhGd2gxeUVoaUpzOG5RX1ZtLWY5SEdCU3FTUzFoSFk4QmE0OENoYmFlQ0RuVTcxYzN1UlRudXBCbGlMLUJIOEgzeFl0ZzYwNWVCV1A3RXZTS3NyMFVEVFBIbzB5V2syN2NHeDk4R05uZFB1V1MtT21ja0l2T0xJdU1rV3MxMGR5NjV3RzhFek5FUFZkMEUtNTZJbUFGR3Y3NXc1V3I4X2lDQ3NqVEsyaTQyOTk4dGNCcmFjbk0yZyIsImFsZ29yaXRobSI6IkhNQUMtU0hBMjU2IiwiaXNzdWVkX2F0IjoxNjU5MDMyNjA0fQ" // swiftlint:disable:this line_length
    static let userID = UInt(111)
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

    static var withNoSignedRequestParameter: [String: Any] {
        filterParameters(withKeys: [Keys.signedRequest])
    }

    static var withInvalidSignedRequestParameter: [String: Any] {
        var parameters = withDefaultParameters
        parameters[Keys.signedRequest] = "some_signed_request"
        return parameters
    }

    private static func filterParameters(withKeys keys: [String]) -> [String: Any] {
        let parameters = withDefaultParameters.filter { !keys.contains($0.0) }
        return parameters
    }
}
