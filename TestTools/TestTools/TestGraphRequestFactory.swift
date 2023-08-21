/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

public final class TestGraphRequestFactory: GraphRequestFactoryProtocol {

  public var stubbedGraphRequest: TestGraphRequest?

  public var capturedGraphPath: String?
  public var capturedParameters: [String: Any]?
  public var capturedTokenString: String?
  public var capturedHTTPMethod: HTTPMethod?
  public var capturedFlags: GraphRequestFlags?
  public var capturedVersion: String?
  public var capturedRequests = [TestGraphRequest]()

  public init() {}

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod: HTTPMethod?,
    flags: GraphRequestFlags
  ) -> GraphRequestProtocol {
    makeRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: tokenString,
      httpMethod: httpMethod,
      flags: flags
    )
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    httpMethod: HTTPMethod
  ) -> GraphRequestProtocol {
    makeRequest(
      graphPath: graphPath,
      parameters: parameters,
      httpMethod: httpMethod
    )
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    version: String?,
    httpMethod: HTTPMethod
  ) -> GraphRequestProtocol {
    makeRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: tokenString,
      version: version,
      httpMethod: httpMethod
    )
  }

  public func createGraphRequest(withGraphPath graphPath: String) -> GraphRequestProtocol {
    makeRequest(graphPath: graphPath)
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any]
  ) -> GraphRequestProtocol {
    makeRequest(graphPath: graphPath, parameters: parameters)
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    flags: GraphRequestFlags
  ) -> GraphRequestProtocol {
    makeRequest(graphPath: graphPath, parameters: parameters, flags: flags)
  }

  private func makeRequest(
    graphPath: String,
    parameters: [String: Any]? = nil,
    tokenString: String? = nil,
    version: String? = nil,
    httpMethod: HTTPMethod? = nil,
    flags: GraphRequestFlags? = nil
  ) -> TestGraphRequest {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedTokenString = tokenString
    capturedVersion = version
    capturedHTTPMethod = httpMethod
    capturedFlags = flags

    let newRequest = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: tokenString,
      httpMethod: httpMethod,
      version: version,
      flags: flags
    )

    let returnedRequest = stubbedGraphRequest ?? newRequest
    capturedRequests.append(returnedRequest)
    return returnedRequest
  }
}
