/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class GraphRequestPiggybackManagerProviderTests: XCTestCase {

  func testDefaultPiggybackManager() {
    XCTAssertTrue(
      GraphRequestPiggybackManagerProvider.piggybackManager() is GraphRequestPiggybackManager.Type,
      "Should provide the expected concrete piggyback manager"
    )
  }
}
