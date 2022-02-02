/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

final class AppLinkURLFactoryTests: XCTestCase {

  func testCreatingAppLinkURL() {
    let factory = AppLinkURLFactory()
    XCTAssertTrue(
      factory.createAppLinkURL(with: SampleURLs.valid) is AppLinkURL,
      "Should create an app link url of the expected concrete type"
    )
  }
}
