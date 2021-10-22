/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class GraphRequestConnectionFactoryTests: XCTestCase {

  let factory = GraphRequestConnectionFactory()

  func testCreatingConnection() {
    if (factory.createGraphRequestConnection() as? GraphRequestConnection) == nil {
      XCTFail("Should create a connection of the correct concrete type")
    }
  }

  func testCreatingConnections() {
    let connection = factory.createGraphRequestConnection()
    let connection2 = factory.createGraphRequestConnection()

    XCTAssertFalse(
      connection === connection2,
      "Connections should be unique"
    )
  }
}
