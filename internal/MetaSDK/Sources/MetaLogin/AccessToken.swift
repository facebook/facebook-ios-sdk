/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// It represents an immutable access token for using Meta SDK APIs
public struct AccessToken: Codable {
    /// The access token string obtained from Oauth Server
    public let tokenString: String

    /// The expiration date associated with the token . If no expirationDate set, an infinite expiration time is assumed
    public let expirationDate: Date

    /// The expiration date associated with the data access permission
    public let dataAccessExpirationDate: Date

    /// Shows if the token is expired
    public var isExpired: Bool {
        return expirationDate < Date()
    }

    /// Shows if the data access permission is expired
    public var isDataAccessExpired: Bool {
        return dataAccessExpirationDate < Date()
    }

    init?(
        tokenString: String,
        expirationDate: Date = .distantFuture,
        dataAccessExpirationDate: Date = .distantFuture,
        creationDate: Date = Date()   // Set for testing only
    ) {
        guard
            !tokenString.isEmpty &&
            expirationDate > creationDate &&
            dataAccessExpirationDate > creationDate
        else {
            return nil
        }
        self.expirationDate = expirationDate
        self.dataAccessExpirationDate = expirationDate
        self.tokenString = tokenString
    }
}
