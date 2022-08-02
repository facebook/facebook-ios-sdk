/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public enum SampleURLs {
    public static let example = URL(string: "https://www.example.com")!
    public static let loginRedirect = URL(string: "fbconnect://success")!

    public static func example(path: String) -> URL {
        example.appendingPathComponent(path)
    }

    public static func example(queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: example, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        return components.url!
    }

    public static func loginRedirect(path: String) -> URL {
        loginRedirect.appendingPathComponent(path)
    }
}
