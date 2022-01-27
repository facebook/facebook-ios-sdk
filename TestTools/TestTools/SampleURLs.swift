/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public enum SampleURLs {
  // swiftlint:disable force_unwrapping
  public static let valid = URL(string: "https://www.example.com")!
  public static let validApp = URL(string: "fb://test.com")!
  public static let validPNG = URL(string: "https://www.example.com/babyamnimal.png")!
  // swiftlint:enable force_unwrapping

  public static func valid(path: String) -> URL {
    valid.appendingPathComponent(path)
  }

  public static func valid(queryItems: [URLQueryItem]) -> URL {
    // swiftlint:disable:next force_unwrapping
    var components = URLComponents(url: valid, resolvingAgainstBaseURL: false)!
    components.queryItems = queryItems
    return components.url! // swiftlint:disable:this force_unwrapping
  }
}

public enum SampleURLRequest {
  public static let valid = URLRequest(url: SampleURLs.valid)
}
