/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

@objcMembers
public class TestGraphRequest: NSObject, GraphRequestProtocol {
  public var isGraphErrorRecoveryDisabled = false
  public var hasAttachments = false
  public var parameters: [String: Any] = [:]
  public var tokenString: String?
  public var graphPath: String = ""
  public var httpMethod = HTTPMethod.get
  public var version: String = ""
  public var flags: GraphRequestFlags = []
  public var stubbedConnection = TestGraphRequestConnection()
  public var capturedCompletionHandler: GraphRequestCompletion?
  public var startCallCount = 0
  public var cancelCallCount = 0

  public convenience init(
    graphPath: String,
    HTTPMethod: HTTPMethod
  ) {
    self.init()

    self.graphPath = graphPath
    self.httpMethod = HTTPMethod
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any]
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    HTTPMethod: HTTPMethod
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.httpMethod = HTTPMethod
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    flags: GraphRequestFlags
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.flags = flags
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    tokenString: String?
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.tokenString = tokenString
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    HTTPMethod: HTTPMethod,
    flags: GraphRequestFlags
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.tokenString = tokenString
    self.graphPath = graphPath
    self.httpMethod = HTTPMethod
    self.flags = flags
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    HTTPMethod: HTTPMethod,
    version: String
  ) {
    self.init()

    self.parameters = parameters
    self.tokenString = tokenString
    self.graphPath = graphPath
    self.httpMethod = HTTPMethod
    self.version = version
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
