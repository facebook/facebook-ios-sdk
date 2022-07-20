/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public enum SampleURLs {
  // swiftlint:next force_unwrapping
  public static let valid = URL(string: "https://www.example.com")!

  public static func valid(path: String) -> URL {
    valid.appendingPathComponent(path)
  }

  public static func valid(queryItems: [URLQueryItem]) -> URL {
    var components = URLComponents(url: valid, resolvingAgainstBaseURL: false)!
    components.queryItems = queryItems
    return components.url!
  }
}
