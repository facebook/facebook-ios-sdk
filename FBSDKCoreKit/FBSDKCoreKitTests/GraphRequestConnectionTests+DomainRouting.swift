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

// Split out of GraphRequestConnectionTests to keep that type under the body-length limit.
extension GraphRequestConnectionTests {

  // MARK: Domain Split Single Request Tests

  func testSingleRequestInATTScopeAdvertiserTrackingEnabled() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "activities",
      forAppEvents: true,
      useAlternativeDefaultDomainPrefix: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testSingleRequestInATTScopeAdvertiserTrackingNotEnabled() throws {
    settings.isAdvertiserTrackingEnabled = false
    AuthenticationToken.current = nil
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "activities",
      forAppEvents: true,
      useAlternativeDefaultDomainPrefix: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint2Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testSingleRequestToNonAppActivitiesEndpoint() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "activities",
      forAppEvents: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)
    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testSingleRequestNotInATTScope() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testSingleRequestToAdsEndpointNotInATTScope() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "ads_endpoint",
      forAppEvents: false,
      useAlternativeDefaultDomainPrefix: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint2Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testSingleRequestToNonAdsEndpoint() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "non_ads_endpoint",
      forAppEvents: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testSingleRequestToVideosEndpoint() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "mockVideoId/videos",
      forAppEvents: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    XCTAssertEqual(urlComponents.host, "graph-video.facebook.com")
  }

  func testSingleRequestToGamingDomain() throws {
    settings.isAdvertiserTrackingEnabled = false
    AuthenticationToken.current = AuthenticationToken(
      tokenString: "test_token_string",
      nonce: "test_nonce",
      graphDomain: "gaming"
    )
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    XCTAssertEqual(urlComponents.host, "graph.fb.gg")
  }

  func testSingleRequestToGamingDomainVideosEndpoint() throws {
    settings.isAdvertiserTrackingEnabled = false
    AuthenticationToken.current = AuthenticationToken(
      tokenString: "test_token_string",
      nonce: "test_nonce",
      graphDomain: "gaming"
    )
    let singleRequest = DomainHandlerTests.getSingleTestRequest(
      graphPath: "mockVideoId/videos",
      forAppEvents: false
    )
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    XCTAssertEqual(urlComponents.host, "graph-video.fb.gg")
  }

  func testSingleRequestToCustomAudienceThirdPartyEndpointWithTrackingAllowed() throws {
    settings.isAdvertiserTrackingEnabled = true
    AppEvents.shared.settings = settings
    AppEvents.shared.graphRequestFactory = GraphRequestFactory()
    AppEvents.shared.isConfigured = true
    guard let customAudienceRequest = AppEvents.shared.requestForCustomAudienceThirdPartyID(
      accessToken: SampleAccessTokens.validToken
    ) else {
      XCTFail("Should be able to create custom audience third party request")
      return
    }
    connection.add(customAudienceRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testSingleRequestToAppIndexingSessionEndpointWithTrackingEnabled() throws {
    settings.isAdvertiserTrackingEnabled = true
    guard let appID = settings.appID else {
      XCTFail("Should have an app ID")
      return
    }
    guard let sessionID = _CodelessIndexer.currentSessionDeviceID else {
      XCTFail("Should provide a session device identifier")
      return
    }
    let params: [String: Any] = [
      "device_session_id": _CodelessIndexer.extInfo,
      "extinfo": sessionID,
    ]
    let appIndexingSessionRequest = TestGraphRequest(
      graphPath: "\(appID)/app_indexing_session",
      parameters: params,
      httpMethod: .post,
      useAlternativeDefaultDomainPrefix: false
    )
    connection.add(appIndexingSessionRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  // MARK: Domain Split Batch Request Tests

  func testBatchRequestInAttScopeAdvertiserTrackingEnabled() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil

    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    let request2 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "activities",
      forAppEvents: true,
      useAlternativeDefaultDomainPrefix: false
    )
    connection.add(request2) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testBatchRequestInAttScopeAdvertiserTrackingNotEnabled() throws {
    settings.isAdvertiserTrackingEnabled = false
    AuthenticationToken.current = nil

    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    let request2 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "activities",
      forAppEvents: true,
      useAlternativeDefaultDomainPrefix: false
    )
    connection.add(request2) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint2Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testBatchRequestNotInAttScope() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil

    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    let request2 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "activities",
      forAppEvents: false
    )
    connection.add(request2) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testBatchRequestToGamingDomain() throws {
    settings.isAdvertiserTrackingEnabled = false
    AuthenticationToken.current = AuthenticationToken(
      tokenString: "test_token_string",
      nonce: "test_nonce",
      graphDomain: "gaming"
    )

    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    let request2 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_2_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request2) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    XCTAssertEqual(urlComponents.host, "graph.fb.gg")
  }

  func testBatchRequestToCustomAudienceThirdPartyEndpointWithTrackingAllowed() throws {
    settings.isAdvertiserTrackingEnabled = true
    AppEvents.shared.settings = settings
    AppEvents.shared.graphRequestFactory = GraphRequestFactory()
    AppEvents.shared.isConfigured = true
    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    guard let customAudienceRequest = AppEvents.shared.requestForCustomAudienceThirdPartyID(
      accessToken: SampleAccessTokens.validToken
    ) else {
      XCTFail("Should be able to create custom audience third party request")
      return
    }
    connection.add(customAudienceRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testBatchRequestToAppIndexingSessionEndpointWithTrackingEnabled() throws {
    settings.isAdvertiserTrackingEnabled = true
    guard let appID = settings.appID else {
      XCTFail("Should have an app ID")
      return
    }
    guard let sessionID = _CodelessIndexer.currentSessionDeviceID else {
      XCTFail("Should provide a session device identifier")
      return
    }
    let params: [String: Any] = [
      "device_session_id": _CodelessIndexer.extInfo,
      "extinfo": sessionID,
    ]
    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    let appIndexingSessionRequest = TestGraphRequest(
      graphPath: "\(appID)/app_indexing_session",
      parameters: params,
      httpMethod: .post,
      useAlternativeDefaultDomainPrefix: false
    )
    connection.add(appIndexingSessionRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testDefaultURLPrefixForBatchRequest1() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil

    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "test_endpoint_2_not_in_att_scope",
        forAppEvents: false
      )
    connection.add(request2) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint1Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }

  func testDefaultURLPrefixForBatchRequest2() throws {
    settings.isAdvertiserTrackingEnabled = true
    AuthenticationToken.current = nil

    let request1 = DomainHandlerTests.getSingleTestRequest(
      graphPath: "test_endpoint_not_in_att_scope",
      forAppEvents: false
    )
    connection.add(request1) { _, _, _ in }
    let request2 =
      DomainHandlerTests.getSingleTestRequest(
        graphPath: "ads_endpoint",
        forAppEvents: false,
        useAlternativeDefaultDomainPrefix: false
      )
    connection.add(request2) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled() {
      XCTAssertEqual(urlComponents.host, endpoint2Domain)
    } else {
      XCTAssertEqual(urlComponents.host, endpoint3Domain)
    }
  }
}
