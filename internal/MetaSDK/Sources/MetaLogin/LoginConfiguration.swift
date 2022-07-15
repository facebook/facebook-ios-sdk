// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

/// A configuration to use for modifying the behavior of a login attempt.
public struct LoginConfiguration {

    /// The requested permissions for the login attempt. Defaults to an empty set.
    public let permissions: [String]

    /// The Facebook App ID used by the SDK.
    /// If not explicitly set, the default will be read from the application's plist (FacebookAppID).
    /// See setup documentation for instructions
    public let facebookAppID: String

    /// The Meta App ID used by the SDK.
    /// If not explicitly set, the default will be read from the application's plist (MetaAppID).
    /// See setup documentation for instructions
    public let metaAppID: String

    /**
     Attempts to initialize a new configuration with the expected parameters.

     - Parameter permissions: The requested permissions for a login attempt. Permissions must be an array of strings
     that do not contain whitespace.
     - Parameter facebookAppID: the Facebook App ID used by the SDK. If not explicitly set, the default will be read
     from the application's plist (FacebookAppID)
     - Parameter metaAppID: the Meta App ID used by the SDK. If not explicitly set, the default will be read from the
     application's plist (MetaAppID)
     */
    public init?(
        permissions: [String] = [],
        facebookAppID: String? = nil,
        metaAppID: String? = nil
    ) {
        // TODO: Fetch App ID defaults from plist

        guard let facebookAppID = facebookAppID else {
            return nil
        }
        guard let metaAppID = metaAppID else {
            return nil
        }

        self.permissions = permissions
        self.facebookAppID = facebookAppID
        self.metaAppID = metaAppID
    }
}
