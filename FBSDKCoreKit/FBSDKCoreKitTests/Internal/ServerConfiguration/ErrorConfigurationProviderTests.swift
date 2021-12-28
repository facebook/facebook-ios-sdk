/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class ErrorConfigurationProviderTests: XCTestCase {

  func testErrorConfigurationRecoveryProvider() {
    XCTAssertTrue(
      ErrorConfigurationProvider().errorConfiguration() is ErrorConfiguration,
      "The default error configuration provider should provide the expected concrete type"
    )
  }
}
