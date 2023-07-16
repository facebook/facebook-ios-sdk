/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class ProtectedModeManagerTests: XCTestCase {
  let protectedModeManager = ProtectedModeManager()
  let sampleParameters: [AppEvents.ParameterName: Any] = [
    AppEvents.ParameterName.pushCampaign: "fb_mobile_catalog_update",
    AppEvents.ParameterName.productTitle: "Coffee 4",
    AppEvents.ParameterName.logTime: 1686615025,
    AppEvents.ParameterName.implicitlyLogged: true,
  ]

  func testProcessParametersWithoutEnable() {
    XCTAssertEqual(
      protectedModeManager.processParameters(sampleParameters, eventName: AppEvents.Name.addedToCart)?.count,
      4,
      "It should not do the parameter filtering without enbaled"
    )
  }

  func testProcessParametersWithEnable() {
    protectedModeManager.enable()
    XCTAssertEqual(
      protectedModeManager.processParameters(sampleParameters, eventName: AppEvents.Name.addedToCart)?.count,
      3, // should also include PM flag
      "It should do the parameter filtering when enbaled"
    )
  }
}
