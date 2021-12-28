/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

public final class TestURLHoster: URLHosting {
  public var capturedHost: String?
  public var capturedHostPrefix: String?
  public var capturedPath: String?
  public var capturedQueryParameters: [String: String]?
  public var stubbedURL: URL?

  private var url: URL {
    guard let url = stubbedURL else {
      preconditionFailure("Missing stubbed URL")
    }

    return url
  }

  public init(url: URL? = nil) {
    stubbedURL = url
  }

  public func appURL(
    withHost host: String,
    path: String,
    queryParameters: [String: String]
  ) throws -> URL {
    capturedHost = host
    capturedPath = path
    capturedQueryParameters = queryParameters
    return url
  }

  public func facebookURL(
    withHostPrefix hostPrefix: String,
    path: String,
    queryParameters: [String: String]
  ) throws -> URL {
    capturedHostPrefix = hostPrefix
    capturedPath = path
    capturedQueryParameters = queryParameters
    return url
  }
}
