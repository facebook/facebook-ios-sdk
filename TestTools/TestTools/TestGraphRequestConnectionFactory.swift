/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
public class TestGraphRequestConnectionFactory: NSObject, GraphRequestConnectionFactoryProtocol {
  public var stubbedConnection: GraphRequestConnecting?

  public override init() {}

  public init(stubbedConnection: GraphRequestConnecting) {
    self.stubbedConnection = stubbedConnection
  }

  public static func create(
    withStubbedConnection connection: GraphRequestConnecting
  ) -> TestGraphRequestConnectionFactory {
    TestGraphRequestConnectionFactory(stubbedConnection: connection)
  }

  // MARK: - GraphRequestConnectionFactoryProtocol

  public func createGraphRequestConnection() -> GraphRequestConnecting {
    guard let connection = stubbedConnection else {
      fatalError("Must stub a connection for a test connection factory")
    }
    return connection
  }
}
