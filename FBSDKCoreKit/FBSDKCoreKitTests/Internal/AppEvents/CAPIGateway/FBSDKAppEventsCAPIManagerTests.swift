/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import TestTools
import XCTest

class FBSDKAppEventsCAPIManagerTests: XCTestCase {

  enum Values {
    static let datasetID = "id123"
    static let accessKey = "key123"
    static let capiGatewayURL = "www.123.com"
  }

  let factory = TestGraphRequestFactory()
  let settings = TestSettings()

  override func setUp() {
    super.setUp()

    FBSDKAppEventsCAPIManager.shared.configure(factory: factory, settings: settings)
  }

  func testConfigure() {
    XCTAssertEqual(
      factory,
      FBSDKAppEventsCAPIManager.shared.factory as? TestGraphRequestFactory,
      "Should configure with the expected graph request factory"
    )
    XCTAssertEqual(
      settings,
      FBSDKAppEventsCAPIManager.shared.settings as? TestSettings,
      "Should configure with the expected settings"
    )
  }

  func testEnableWithoutAppID() {
    settings.appID = nil

    FBSDKAppEventsCAPIManager.shared.enable()
    XCTAssertTrue(
      factory.capturedRequests.isEmpty,
      "Should not send graph request when app id is nil"
    )
  }

  func testEnableWithNetworkError() {
    settings.appID = "123"

    FBSDKAppEventsCAPIManager.shared.enable()
    guard let completion = factory.capturedRequests.first?.capturedCompletionHandler else {
      return XCTFail("Should start a request with a completion handler")
    }
    completion(nil, nil, SampleError())
    XCTAssertFalse(
      FBSDKAppEventsCAPIManager.shared.isEnabled,
      "CAPI should not be enabled when setting request fails"
    )
  }

  func testEnableWithoutNetworkError() {
    settings.appID = "123"

    FBSDKAppEventsCAPIManager.shared.enable()
    guard let completion = factory.capturedRequests.first?.capturedCompletionHandler else {
      return XCTFail("Should start a request with a completion handler")
    }
    completion(
      nil,
      [
        "data": [
          [
            "is_enabled": true,
            "access_key": Values.accessKey,
            "dataset_id": Values.datasetID,
            "endpoint": Values.capiGatewayURL,
          ],
        ],
      ],
      nil
    )
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.credentials?.accessKey,
      Values.accessKey,
      "Credential's access key should be the same as that in the setting request"
    )
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.credentials?.datasetID,
      Values.datasetID,
      "Credential's access key should be the same as that in the setting request"
    )
    XCTAssertEqual(
      FBSDKTransformerGraphRequestFactory.shared.credentials?.capiGatewayURL,
      Values.capiGatewayURL,
      "Credential's access key should be the same as that in the setting request"
    )
    XCTAssertTrue(
      FBSDKAppEventsCAPIManager.shared.isEnabled,
      "CAPI should be enabled when setting request succeeds"
    )
  }
}
