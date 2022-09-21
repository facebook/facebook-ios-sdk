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

  public static func loginRedirect(queryItems: [URLQueryItem], useFragments: Bool) -> URL {
    var components = URLComponents(url: loginRedirect, resolvingAgainstBaseURL: false)!
    components.queryItems = queryItems
    var url = components.url!.absoluteString

    if useFragments {
      url = url.replacingOccurrences(of: "?", with: "#")
    }
    return URL(string: url)!
  }

  public enum LoginResponses {
    public static let withDefaultParameters = loginRedirect(
      queryItems: SampleRawLoginResponse.withDefaultParameters.queryItems,
      useFragments: true
    )
    public static let withDefaultParametersWithQuery = loginRedirect(
      queryItems: SampleRawLoginResponse.withDefaultParameters.queryItems,
      useFragments: false
    )
    public static let withNoExpirationParameters = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoExpirationParameters.queryItems,
      useFragments: true
    )
    public static let withNoExpiresParameter = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoExpiresParameter.queryItems,
      useFragments: true
    )
    public static let withNoExpiresAndExpiresAtParameters = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoExpiresAndExpiresAtParameters.queryItems,
      useFragments: true
    )
    public static let withEmptyPermissions = loginRedirect(
      queryItems: SampleRawLoginResponse.withEmptyPermissions.queryItems,
      useFragments: true
    )
    public static let withNoAccessTokenAndError = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoAccessTokenAndError.queryItems,
      useFragments: true
    )
    public static let withNoSignedRequestParameter = loginRedirect(
      queryItems: SampleRawLoginResponse.withNoSignedRequestParameter.queryItems,
      useFragments: true
    )
    public static let withInvalidSignedRequestParameter = loginRedirect(
      queryItems: SampleRawLoginResponse.withInvalidSignedRequestParameter.queryItems,
      useFragments: true
    )
    public static let withCancellationRequest = loginRedirect(
      queryItems: SampleRawLoginResponse.withCancellationRequestParameter.queryItems,
      useFragments: true
    )
  }
}

// swiftformat:disable extensionaccesscontrol

private extension Dictionary where Key == String, Value: Any {
  var queryItems: [URLQueryItem] {
    return map {
      URLQueryItem(name: $0, value: $1 as? String)
    }
  }
}

// swiftformat:enable extensionaccesscontrol
