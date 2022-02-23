/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class GraphRequestFactoryTests: XCTestCase {

  let factory = GraphRequestFactory()

  func testCreatingRequest() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "foo",
      httpMethod: .get,
      flags: [.skipClientToken, .disableErrorRecovery]
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }

    XCTAssertEqual(
      graphRequest.graphPath,
      "me",
      "Should provide the graph path to the underlying type"
    )
    XCTAssertEqual(
      graphRequest.parameters as? [String: String],
      ["some": "thing"],
      "Should provide the parameters to the underlying type"
    )
    XCTAssertEqual(
      graphRequest.httpMethod,
      .get,
      "Should provide the HTTP method to the underlying type"
    )
  }
}
