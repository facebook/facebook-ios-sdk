/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import Foundation
import TestTools
import XCTest

final class DomainHandlerTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var settings: TestSettings!
  // swiftlint:enable implicitly_unwrapped_optional
  static var testDomainConfiguration = [
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
    "test_endpoint_in_att_scope": [
      "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
      "att_opt_out_domain_prefix": kEndpoint2URLPrefix,
    ],
    "default_config": [
      "default_domain_prefix": kEndpoint2URLPrefix,
      "default_alternative_domain_prefix": kEndpoint1URLPrefix,
      "enable_for_early_versions": false,
    ],
  ]

  class func getSingleTestRequest(
    graphPath: String,
    forAppEvents: Bool,
    useAlternativeDefaultDomainPrefix: Bool = true
  ) -> GraphRequestProtocol {
    let parameters: [String: Any] = [
      "first_key": "first_value",
    ]
    return TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      httpMethod: .post,
      forAppEvents: forAppEvents,
      useAlternativeDefaultDomainPrefix: useAlternativeDefaultDomainPrefix
    )
  }

  class func getBatchTestRequestFor(requests: [GraphRequestProtocol]) -> [GraphRequestMetadata] {
    var batchRequest = [GraphRequestMetadata]()
    for request in requests {
      let requestMetadata = GraphRequestMetadata(request: request, completionHandler: nil, batchParameters: [:])
      batchRequest.append(requestMetadata)
    }
    return batchRequest
  }

  class func configureDomainHandlerForTesting(enableForEarlyVersions: Bool = false) {
    testDomainConfiguration["default_config"]?["enable_for_early_versions"] = enableForEarlyVersions
    _DomainHandler.sharedInstance().domainConfigurationProvider =
      TestDomainConfigurationManager(domainInfo: testDomainConfiguration)
  }

  override func setUp() {
    super.setUp()
    DomainHandlerTests.configureDomainHandlerForTesting()
    settings = TestSettings()
    settings.appID = "MockAppID"
    GraphRequest.configure(
      settings: settings,
      currentAccessTokenStringProvider: TestAccessTokenWallet.self,
      graphRequestConnectionFactory: TestGraphRequestConnectionFactory()
    )
  }

  override func tearDown() {
    super.tearDown()
    settings = nil
  }

  // MARK: Single Request Tests

  func testURLPrefixForFetchingDomainConfig() {
    if #available(iOS 14.5, *) {} else {
      return
    }
    guard let appID = settings.appID else {
      XCTFail("Should have an app id")
      return
    }
    let parameters = ["fields": "server_domain_infos"]
    let domainConfigRequest = GraphRequest(graphPath: appID, parameters: parameters, httpMethod: .get)
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: domainConfigRequest,
      isAdvertiserTrackingEnabled: true
    )
    XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
  }

  func testURLPrefixForSingleRequestPostToActivitiesEndpointAdvertiserTrackingEnabled() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleRequestPostToActivitiesEndpointAdvertiserTrackingNotEnabled() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleRequestPostToActivitiesEndpointNotForAppEvents() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: true
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleRequestPostToTestEndpointInATTScopeAdvertiserTrackingEnabled() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleRequestPostToTestEndpointInATTScopeAdvertiserTrackingNotEnabled() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleRequestPostToTestEndpointNotInATTScopeAdvertiserTrackingEnabled() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: true
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleRequestPostToTestEndpointNotInATTScopeAdvertiserTrackingNotEnabled() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: true
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleRequestPostToVideosEndpoint() {
    AuthenticationToken.current = nil
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "mockVideoId/videos",
        forAppEvents: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    XCTAssertEqual(urlPrefix, "graph-video.")
  }

  func testURLPrefixForSingleRequestForGamingDomain() {
    AuthenticationToken.current = AuthenticationToken(
      tokenString: "test_token_string",
      nonce: "test_nonce",
      graphDomain: "gaming"
    )
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: false
    )
    XCTAssertEqual(urlPrefix, "graph.")
  }

  func testURLPrefixForSingleRequestForGamingDomainVideosEndpoint() {
    AuthenticationToken.current = AuthenticationToken(
      tokenString: "test_token_string",
      nonce: "test_nonce",
      graphDomain: "gaming"
    )
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "mockVideoId/videos",
        forAppEvents: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: false
    )
    XCTAssertEqual(urlPrefix, "graph-video.")
  }

  func testURLPrefixForSingleCustomAudienceThirdPartyRequestAdvertiserTrackingEnabled() {
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "custom_audience_third_party_id",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleCustomAudienceThirdPartyRequestAdvertiserTrackingNotEnabled() {
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "custom_audience_third_party_id",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleAppIndexingSessionRequestAdvertiserTrackingEnabled() {
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "app_indexing_session",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForSingleAppIndexingSessionRequestAdvertiserTrackingNotEnabled() {
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "app_indexing_session",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForAdsEndpointNotInATTScope() {
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "ads_endpoint",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForNonAdsEndpoint() {
    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "non_ads_endpoint",
        forAppEvents: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  // MARK: Batch Request Tests

  func testURLPrefixForBatchRequestOneAdvertiserTrackingEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "activities",
      forAppEvents: true,
      useAlternativeDefaultDomainPrefix: false
    )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestOneAdvertiserTrackingNotEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestTwo() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(graphPath: "activities", forAppEvents: false)
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestThree() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_2_not_in_att_scope",
        forAppEvents: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestFourAdvertiserTrackingEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestFourAdvertiserTrackingNotEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestFiveAdvertiserTrackingEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestFiveAdvertiserTrackingNotEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(graphPath: "activities", forAppEvents: false)
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestSixAdvertiserTrackingEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestSixAdvertiserTrackingNotEnabled() {
    AuthenticationToken.current = nil
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_in_att_scope",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: false
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testURLPrefixForBatchRequestForGamingDomain() {
    AuthenticationToken.current = AuthenticationToken(
      tokenString: "test_token_string",
      nonce: "test_nonce",
      graphDomain: "gaming"
    )
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_2_not_in_att_scope",
        forAppEvents: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: false
    )
    XCTAssertEqual(urlPrefix, "graph.")
  }

  func testDefaultURLPrefixForBatchRequest1() {
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_2_not_in_att_scope",
        forAppEvents: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  func testDefaultURLPrefixForBatchRequest2() {
    let request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "ads_endpoint",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlPrefix, "\(kEndpoint2URLPrefix).")
    } else {
      XCTAssertEqual(urlPrefix, "graph.")
    }
  }

  // MARK: Test Early Versions

  func testIsDomainHandlingEnabled() {
    DomainHandlerTests.configureDomainHandlerForTesting()
    if #available(iOS 17.0, *) {
      XCTAssertTrue(
        _DomainHandler.sharedInstance().isDomainHandlingEnabled(),
        "Domain handling should be enabled for iOS 17+"
      )
    }
    if #available(iOS 17.0, *) {} else {
      XCTAssertFalse(
        _DomainHandler.sharedInstance().isDomainHandlingEnabled(),
        "Domain handling should not be enabled for < iOS 17"
      )
    }
    DomainHandlerTests.configureDomainHandlerForTesting(enableForEarlyVersions: true)
    if #available(iOS 17.0, *) {
      XCTAssertTrue(
        _DomainHandler.sharedInstance().isDomainHandlingEnabled(),
        "Domain handling should be enabled for iOS 17+"
      )
    }
    if #available(iOS 17.0, *) {} else {
      if #available(iOS 14.5, *) {
        XCTAssertTrue(
          _DomainHandler.sharedInstance().isDomainHandlingEnabled(),
          "Domain handling should be enabled for iOS 14.5+"
        )
      } else {
        XCTAssertFalse(
          _DomainHandler.sharedInstance().isDomainHandlingEnabled(),
          "Domain handling should not be enabled for < iOS 14.5"
        )
      }
    }
  }

  func testSingleRequestsOnEarlyVersions() {
    if #available(iOS 14.5, *) {} else {
      return
    }
    DomainHandlerTests.configureDomainHandlerForTesting(enableForEarlyVersions: true)
    AuthenticationToken.current = nil

    let request =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request,
      isAdvertiserTrackingEnabled: true
    )
    XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")

    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix2 = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request2,
      isAdvertiserTrackingEnabled: false
    )
    XCTAssertEqual(urlPrefix2, "\(kEndpoint2URLPrefix).")

    let request3 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "ads_endpoint",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    let urlPrefix3 = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request3,
      isAdvertiserTrackingEnabled: true
    )
    XCTAssertEqual(urlPrefix3, "\(kEndpoint2URLPrefix).")

    let request4 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "non_ads_endpoint",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: true
      )
    let urlPrefix4 = _DomainHandler.sharedInstance().getURLPrefix(
      forSingleRequest: request4,
      isAdvertiserTrackingEnabled: true
    )
    XCTAssertEqual(urlPrefix4, "\(kEndpoint1URLPrefix).")
  }

  func testBatchRequestsOnEarlyVersions() {
    if #available(iOS 14.5, *) {} else {
      return
    }
    DomainHandlerTests.configureDomainHandlerForTesting(enableForEarlyVersions: true)
    AuthenticationToken.current = nil

    var request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    var request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let batchRequest = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest,
      isAdvertiserTrackingEnabled: true
    )
    XCTAssertEqual(urlPrefix, "\(kEndpoint1URLPrefix).")

    request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "activities",
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      )
    request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let batchRequest2 = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix2 = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest2,
      isAdvertiserTrackingEnabled: false
    )
    XCTAssertEqual(urlPrefix2, "\(kEndpoint2URLPrefix).")

    request1 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "non_ads_endpoint",
        forAppEvents: false
      )
    request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_not_in_att_scope",
        forAppEvents: false
      )
    let batchRequest3 = DomainHandlerTests.getBatchTestRequestFor(requests: [request1, request2])
    let urlPrefix3 = _DomainHandler.sharedInstance().getURLPrefix(
      forBatchRequest: batchRequest3,
      isAdvertiserTrackingEnabled: true
    )
    XCTAssertEqual(urlPrefix3, "\(kEndpoint1URLPrefix).")
  }
}
