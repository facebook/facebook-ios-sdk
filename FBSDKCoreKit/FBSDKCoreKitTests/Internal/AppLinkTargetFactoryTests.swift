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

final class AppLinkTargetFactoryTests: XCTestCase {

  let url = SampleURLs.valid
  let appStoreId = "123"

  func testCreatingAppLinkTarget() throws {
    let factory = AppLinkTargetFactory()
    let target = try XCTUnwrap(
      factory.createAppLinkTarget(
        url: url,
        appStoreId: appStoreId,
        appName: name
      ) as? AppLinkTarget,
      "Should create an app link target of the expected concrete type"
    )

    XCTAssertEqual(
      target.url,
      url,
      "Should use the provided url to create the app link target"
    )
    XCTAssertEqual(
      target.appStoreId,
      appStoreId,
      "Should use the provided app store identifier to create the app link target"
    )
    XCTAssertEqual(
      target.appName,
      name,
      "Should use the provided name to create the app link target"
    )
  }
}
