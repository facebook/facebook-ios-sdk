/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

public final class TestGraphRequest: GraphRequestProtocol {
  public var isGraphErrorRecoveryDisabled = false
  public let hasAttachments = false
  public var parameters: [String: Any]
  public let tokenString: String?
  public let graphPath: String
  public let httpMethod: HTTPMethod
  public let version: String
  public let flags: GraphRequestFlags
  public var stubbedConnection = TestGraphRequestConnection()
  public var capturedCompletionHandler: GraphRequestCompletion?
  public var startCallCount = 0
  public var cancelCallCount = 0

  public init(
    graphPath: String = "",
    parameters: [String: Any]? = nil,
    tokenString: String? = nil,
    httpMethod: HTTPMethod? = nil,
    version: String? = nil,
    flags: GraphRequestFlags? = nil
  ) {
    self.graphPath = graphPath
    self.parameters = parameters ?? [:]
    self.tokenString = tokenString
    self.httpMethod = httpMethod ?? .get
    self.version = version ?? ""
    self.flags = flags ?? []
  }

  public func start(completion handler: GraphRequestCompletion? = nil) -> GraphRequestConnecting {
    capturedCompletionHandler = handler
    startCallCount += 1

    return stubbedConnection
  }

  public func cancel() {
    cancelCallCount += 1
  }

  public func formattedDescription() -> String {
    "Test graph request"
  }
}
