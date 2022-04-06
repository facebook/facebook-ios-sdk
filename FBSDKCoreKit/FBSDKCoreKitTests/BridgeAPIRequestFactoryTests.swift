/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class BridgeAPIRequestFactoryTests: XCTestCase {
  let factory = BridgeAPIRequestFactory()

  func testFactoryMakesRequests() {
    XCTAssertNotNil(
      factory.bridgeAPIRequest(
        with: .web,
        scheme: URLScheme.https.rawValue,
        methodName: nil,
        parameters: nil,
        userInfo: nil
      )
    )
  }
}
