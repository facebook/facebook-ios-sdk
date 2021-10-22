/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class FBSDKServerConfigurationManagerTests: XCTestCase {

  func testDefaultDependencies() {
    ServerConfigurationManager.shared.reset()

    XCTAssertNil(
      ServerConfigurationManager.shared.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
  }

  func testParsingResponses() {
    for _ in 0..<100 {
      ServerConfigurationManager.shared.processLoadRequestResponse(
        RawServerConfigurationResponseFixtures.random,
        error: nil,
        appID: name
      )
    }
  }
}
