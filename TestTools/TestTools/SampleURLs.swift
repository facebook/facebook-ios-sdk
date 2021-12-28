/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

// swiftlint:disable force_unwrapping
public enum SampleURLs {
  public static let valid = URL(string: "https://www.example.com")!
  public static let validApp = URL(string: "fb://test.com")!
  public static let validPNG = URL(string: "https://www.example.com/babyamnimal.png")!

  public static func valid(path: String) -> URL {
    valid.appendingPathComponent(path)
  }

  public static func valid(queryItems: [URLQueryItem]) -> URL {
    var components = URLComponents(url: valid, resolvingAgainstBaseURL: false)!
    components.queryItems = queryItems
    return components.url!
  }
}

public enum SampleURLRequest {
  public static let valid = URLRequest(url: SampleURLs.valid)
}
