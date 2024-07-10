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

final class DomainConfigurationTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var configuration: _DomainConfiguration!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    _DomainConfiguration.setDefaultDomainInfo()
    configuration = _DomainConfiguration.default()
  }

  func testCreatingWithEmptyAppID() {
    configuration = _DomainConfiguration.default()
    let defaultDomainInfo: [String: [String: Any]] = [
      "activities": [
        "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
        "att_opt_out_domain_prefix": kEndpoint2URLPrefix,
      ],
      "custom_audience_third_party_id": [
        "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
        "att_opt_out_domain_prefix": kEndpoint1URLPrefix,
      ],
      "app_indexing_session": [
        "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
        "att_opt_out_domain_prefix": kEndpoint1URLPrefix,
      ],
      "default_config": [
        "default_domain_prefix": kEndpoint2URLPrefix,
        "default_alternative_domain_prefix": kEndpoint1URLPrefix,
        "enable_for_early_versions": false,
      ],
    ]

    guard let defailtDomainInfo = configuration.domainInfo else {
      XCTFail("Should not be nil")
      return
    }
    XCTAssertTrue(
      NSDictionary(dictionary: defailtDomainInfo).isEqual(to: defaultDomainInfo),
      "Should use the given app identifier regardless of value"
    )
  }

  func testEncodingAndDecoding() throws {
    let object = try XCTUnwrap(configuration)
    let decodedObject = try CodabilityTesting.encodeAndDecode(object)
    let errorMsg = "FBSDKDomainConfiguration should be encodable and decodable"

    XCTAssertNotIdentical(decodedObject, object, errorMsg)
    XCTAssertEqual(decodedObject.version, object.version, errorMsg)
    XCTAssertEqual(decodedObject.timestamp, object.timestamp, errorMsg)
    guard let decodedDomainInfo = decodedObject.domainInfo,
          let objectDomainInfo = object.domainInfo else {
      XCTFail("Should not be nil")
      return
    }
    XCTAssertTrue(NSDictionary(dictionary: decodedDomainInfo).isEqual(to: objectDomainInfo), errorMsg)
  }
}
