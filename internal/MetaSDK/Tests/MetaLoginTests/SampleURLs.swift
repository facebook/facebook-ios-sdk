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

  public static func loginRedirect(queryItems: [URLQueryItem]) -> URL {
    var components = URLComponents(url: loginRedirect, resolvingAgainstBaseURL: false)!
    components.queryItems = queryItems
    var url = components.url!.absoluteString
    url = url.replacingOccurrences(of: "?", with: "#")

    return URL(string: url)!
  }

  public enum LoginResponses {
    public static let withDefaultParameters = loginRedirect(
      queryItems: SampleRawLoginResponse.withDefaultParameters.queryItems
    )
    public static let withNoExpirationParameters = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoExpirationParameters.queryItems
    )
    public static let withNoExpiresParameter = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoExpiresParameter.queryItems
    )
    public static let withNoExpiresAndExpiresAtParameters = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoExpiresAndExpiresAtParameters.queryItems
    )
    public static let withEmptyPermissions = loginRedirect(
      queryItems: SampleRawLoginResponse.withEmptyPermissions.queryItems
    )
    public static let withNoAccessToken = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoAccessToken.queryItems
    )
    public static let withNoSignedRequestParameter = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoSignedRequestParameter.queryItems
    )
    public static let withInvalidSignedRequestParameter = loginRedirect(
      queryItems: SampleRawLoginResponse.withInvalidSignedRequestParameter.queryItems
    )
  }
}

private extension Dictionary where Key == String, Value: Any {
  var queryItems: [URLQueryItem] {
    return map {
      URLQueryItem(name: $0, value: $1 as? String)
    }
  }
}
