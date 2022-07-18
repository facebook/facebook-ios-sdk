// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

/// Represents user login information including both user and authentication data
public class UserSession: Codable {
    
    /// The id of the user
    public let userId: UInt
    /// It represents login account type (Facebook/Meta)
    public let graphDomain: GraphDomain
    /// Access token for using Meta SDK APIs
    public internal(set) var accessToken: AccessToken
    /// The permissions that were requested when the token was obtained
    public internal(set) var requestedPermissions: [String]
    /// The permissions that were declined when the token was obtained
    public internal(set) var declinedPermissions: [String]
    
    internal init(
        userId: UInt,
        graphDomain: GraphDomain,
        accessToken: AccessToken,
        requestedPermissions: [String],
        declinedPermissions: [String]
    ) {
        self.accessToken = accessToken
        self.graphDomain = graphDomain
        self.requestedPermissions = requestedPermissions
        self.userId = userId
        self.declinedPermissions = declinedPermissions;
    }
}
