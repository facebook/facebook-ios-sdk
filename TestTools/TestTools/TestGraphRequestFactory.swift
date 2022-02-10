/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public final class TestGraphRequestFactory: NSObject, GraphRequestFactoryProtocol {

  public var capturedGraphPath: String?
  public var capturedParameters = [String: Any]()
  public var capturedTokenString: String?
  public var capturedHttpMethod: HTTPMethod?
  public var capturedFlags: GraphRequestFlags = []
  public var capturedRequests = [TestGraphRequest]()

  // MARK: - GraphRequestFactoryProtocol

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod method: HTTPMethod?,
    flags: GraphRequestFlags
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedTokenString = tokenString
    capturedHttpMethod = method
    capturedFlags = flags

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: tokenString,
      HTTPMethod: method ?? .get,
      flags: flags
    )
    capturedRequests.append(request)
    return request
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    httpMethod method: HTTPMethod
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedHttpMethod = method

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      HTTPMethod: method
    )
    capturedRequests.append(request)
    return request
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    version: String?,
    httpMethod method: HTTPMethod
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedTokenString = tokenString
    capturedHttpMethod = method

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: tokenString,
      HTTPMethod: method,
      flags: []
    )
    capturedRequests.append(request)
    return request
  }

  public func createGraphRequest(
    withGraphPath graphPath: String
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath

    let request = TestGraphRequest(graphPath: graphPath, HTTPMethod: .get)
    capturedRequests.append(request)
    return request
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any]
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      HTTPMethod: .get
    )
    capturedRequests.append(request)
    return request
  }

  public func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    flags: GraphRequestFlags
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedFlags = flags

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: nil,
      HTTPMethod: .get,
      flags: flags
    )
    capturedRequests.append(request)
    return request
  }
}
