/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class AppLinkFactoryTests: XCTestCase {

  let sourceURL = SampleURLs.valid(path: "source")
  let webURL = SampleURLs.valid(path: "webURL")
  let target = TestAppLinkTarget(url: nil, appStoreId: nil, appName: "foo")
  let isBackToReferrer = Bool.random()

  func testCreatingAppLink() {
    let factory = AppLinkFactory()
    guard let appLink = factory.createAppLink(
      sourceURL: sourceURL,
      targets: [target],
      webURL: webURL,
      isBackToReferrer: isBackToReferrer
    ) as? AppLink
    else {
      return XCTFail("Should create the app links of the expected concrete type")
    }

    XCTAssertEqual(
      appLink.sourceURL,
      sourceURL,
      "Should use the provided source URL to create the app link"
    )
    XCTAssertEqual(
      appLink.webURL,
      webURL,
      "Should use the provided web URL to create the app link"
    )
    XCTAssertTrue(
      appLink.targets[0] as? TestAppLinkTarget === target,
      "Should use the provided targets to create the app link"
    )
    XCTAssertEqual(
      appLink.isBackToReferrer,
      isBackToReferrer,
      "Should use the provided is back to referrer flag to create the app link"
    )
  }
}
