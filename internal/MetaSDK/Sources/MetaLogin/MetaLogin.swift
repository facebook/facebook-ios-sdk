/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// TODO: Define login results with custom type
/// Login Result Block
public typealias LoginCompletion = (Result<String, Error>) -> Void

/// Provides methods for logging the user in and out.
public struct MetaLogin {

    public init() {}

    /**
     Logs the user in or authorizes additional permissions.
     - Parameter configuration: The login configuration to use. If not explicitly set, the default
     configuration will be used
     - Parameter param: completion the login completion handler.
     */
    public func logIn(
        configuration: LoginConfiguration? = LoginConfiguration(),
        completion: @escaping LoginCompletion
    ) {
        // TODO: Call URL Opener
        completion(.success("This is a dummy result"))
    }
}
