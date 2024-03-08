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

final class GraphRequestTests: XCTestCase {

  let path = "me"
  let parameters = ["fields": ""]
  let version = "v16.0"
  let prefix = "graph."
  let settings = TestSettings()
  var factory = TestGraphRequestConnectionFactory()

  override func setUp() {
    super.setUp()

    AuthenticationToken.current = nil
    GraphRequest.resetClassDependencies()
    AccessToken.resetCurrentAccessTokenCache()
    TestAccessTokenWallet.reset()

    settings.appID = "MockAppID"
    GraphRequest.configure(
      settings: settings,
      currentAccessTokenStringProvider: TestAccessTokenWallet.self,
      graphRequestConnectionFactory: factory
    )
  }

  override func tearDown() {
    settings.appID = nil
    GraphRequest.resetClassDependencies()
    TestAccessTokenWallet.reset()

    super.tearDown()
  }

  // MARK: - Tests

  func testDefaultDependencies() {
    GraphRequest.resetClassDependencies()
    let request = GraphRequest(graphPath: path)

    XCTAssertNil(
      GraphRequest.settings,
      "Should not have default settings"
    )
    XCTAssertNil(
      request.tokenString,
      "Should not have a token string when no token string provider has been provided"
    )
    XCTAssertNil(
      request.graphRequestConnectionFactory,
      "Should not have a default connection factory"
    )
  }

  func testConfiguringWithDependencies() {
    TestAccessTokenWallet.current = SampleAccessTokens.validToken
    let request = GraphRequest(graphPath: path)

    XCTAssertTrue(
      GraphRequest.settings === settings,
      "GraphRequest should store the settings dependency it was configured with"
    )
    XCTAssertEqual(
      request.tokenString,
      TestAccessTokenWallet.tokenString,
      "Should use the token string provider for the token string"
    )
    XCTAssertTrue(
      request.graphRequestConnectionFactory === factory,
      "New instances should use the factory provider configured on the type"
    )
  }

  func testCreatingWithCustomURLSessionProxyFactory() {
    factory = TestGraphRequestConnectionFactory(stubbedConnection: GraphRequestConnection())
    let request = GraphRequest(
      graphPath: path,
      parameters: nil,
      tokenString: nil,
      httpMethod: nil,
      flags: [],
      graphRequestConnectionFactory: factory
    )

    XCTAssertTrue(
      request.graphRequestConnectionFactory === factory,
      "A graph request should persist the session factory it was created with"
    )
  }

  func testUseAlternative1() {
    GraphRequestTests.verifyRequest(
      GraphRequest(graphPath: path, useAlternativeDefaultDomainPrefix: false),
      expectedGraphPath: path,
      expectedParameters: parameters,
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .get,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative2() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        useAlternativeDefaultDomainPrefix: false
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .get,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative3() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        httpMethod: .post,
        useAlternativeDefaultDomainPrefix: false
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .post,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative4() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        tokenString: "test_token_string",
        version: "17.0",
        httpMethod: .post,
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: "test_token_string",
      expectedVersion: "17.0",
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative5() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        flags: [],
        useAlternativeDefaultDomainPrefix: false
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .get,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative6() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        tokenString: "test_token_string",
        httpMethod: HTTPMethod.post.rawValue,
        flags: [],
        useAlternativeDefaultDomainPrefix: false
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: "test_token_string",
      expectedVersion: version,
      expectedMethod: .post,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative7() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        tokenString: "test_token_string",
        httpMethod: HTTPMethod.post.rawValue,
        flags: [],
        forAppEvents: true,
        useAlternativeDefaultDomainPrefix: false
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: "test_token_string",
      expectedVersion: version,
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternativeDefaultValue1() {
    GraphRequestTests.verifyRequest(
      GraphRequest(graphPath: path),
      expectedGraphPath: path,
      expectedParameters: parameters,
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .get,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue2() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"]
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .get,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue3() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        httpMethod: .post
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .post,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue4() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        tokenString: "test_token_string",
        version: "17.0",
        httpMethod: .post,
        forAppEvents: true
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: "test_token_string",
      expectedVersion: "17.0",
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue5() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        flags: []
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .get,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue6() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        tokenString: "test_token_string",
        httpMethod: HTTPMethod.post.rawValue,
        flags: []
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: "test_token_string",
      expectedVersion: version,
      expectedMethod: .post,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue7() {
    GraphRequestTests.verifyRequest(
      GraphRequest(
        graphPath: path,
        parameters: ["key": "value"],
        tokenString: "test_token_string",
        httpMethod: HTTPMethod.post.rawValue,
        flags: [],
        forAppEvents: true
      ),
      expectedGraphPath: path,
      expectedParameters: ["key": "value"],
      expectedTokenString: "test_token_string",
      expectedVersion: version,
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: true
    )
  }

  func testDefaultGETParameters() {
    GraphRequestTests.verifyRequest(
      GraphRequest(graphPath: path),
      expectedGraphPath: path,
      expectedParameters: parameters,
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .get
    )
  }

  func testStartRequestUsesRequestProvidedByFactory() {
    let connection = TestGraphRequestConnection()
    factory = TestGraphRequestConnectionFactory(stubbedConnection: connection)
    let request = GraphRequest(
      graphPath: path,
      parameters: nil,
      tokenString: nil,
      httpMethod: nil,
      flags: [],
      graphRequestConnectionFactory: factory
    )

    request.start { _, _, _ in }
    connection.capturedCompletion?(nil, nil, nil)

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "The graph request should use the provided connection"
    )
  }

  func testGraphRequestGETWithEmptyParameters() {
    [
      GraphRequest(graphPath: path, parameters: [:]),
      GraphRequest(graphPath: path, parameters: [:], flags: []),
      GraphRequest(graphPath: path, parameters: [:], tokenString: nil, version: version, httpMethod: .get),
    ]
      .forEach {
        GraphRequestTests.verifyRequest(
          $0,
          expectedGraphPath: path,
          expectedParameters: [:],
          expectedTokenString: nil,
          expectedVersion: version,
          expectedMethod: .get
        )
      }
  }

  func testGraphRequestGETWithNonEmptyParameters() {
    [
      GraphRequest(graphPath: path, parameters: parameters),
      GraphRequest(graphPath: path, parameters: parameters, flags: []),
      GraphRequest(graphPath: path, parameters: parameters, tokenString: nil, version: version, httpMethod: .get),
    ]
      .forEach {
        GraphRequestTests.verifyRequest(
          $0,
          expectedGraphPath: path,
          expectedParameters: parameters,
          expectedTokenString: nil,
          expectedVersion: version,
          expectedMethod: .get
        )
      }
  }

  func testDefaultPOSTParameters() {
    let request = GraphRequest(graphPath: path, httpMethod: .post)
    GraphRequestTests.verifyRequest(
      request,
      expectedGraphPath: path,
      expectedParameters: [:],
      expectedTokenString: nil,
      expectedVersion: version,
      expectedMethod: .post
    )
  }

  func testGraphRequestPOSTWithEmptyParameters() {
    [
      GraphRequest(graphPath: path, parameters: [:], httpMethod: .post),
      GraphRequest(graphPath: path, parameters: [:], tokenString: nil, version: version, httpMethod: .post),
    ]
      .forEach {
        GraphRequestTests.verifyRequest(
          $0,
          expectedGraphPath: path,
          expectedParameters: [:],
          expectedTokenString: nil,
          expectedVersion: version,
          expectedMethod: .post
        )
      }
  }

  func testGraphRequestPOSTWithNonEmptyParameters() {
    [
      GraphRequest(graphPath: path, parameters: parameters, httpMethod: .post),
      GraphRequest(graphPath: path, parameters: parameters, tokenString: nil, version: version, httpMethod: .post),
    ]
      .forEach {
        GraphRequestTests.verifyRequest(
          $0,
          expectedGraphPath: path,
          expectedParameters: parameters,
          expectedTokenString: nil,
          expectedVersion: version,
          expectedMethod: .post
        )
      }
  }

  func testGraphRequestIsForFetchingDomainConfiguration() {
    let graphRequestFactory = GraphRequestFactory()
    guard let appID = settings.appID else {
      XCTFail("Should have an app id")
      return
    }
    let parameters = ["fields": "server_domain_infos"]
    let domainConfigRequest1 = graphRequestFactory.createGraphRequest(
      withGraphPath: appID,
      parameters: parameters,
      tokenString: nil,
      httpMethod: nil,
      flags: [.skipClientToken, .disableErrorRecovery]
    )
    XCTAssertTrue(
      GraphRequest.isForFetchingDomainConfiguration(request: domainConfigRequest1),
      "Request is for fetching the domain configuration"
    )

    let domainConfigRequest2 = GraphRequest(graphPath: appID, parameters: parameters, httpMethod: .get)
    XCTAssertTrue(
      GraphRequest.isForFetchingDomainConfiguration(request: domainConfigRequest2),
      "Request is for fetching the domain configuration"
    )

    let failingRequest1 = GraphRequest(graphPath: appID, parameters: [:], httpMethod: .get)
    XCTAssertFalse(
      GraphRequest.isForFetchingDomainConfiguration(request: failingRequest1),
      "Request is not for fetching the domain configuration. The parameters are wrong"
    )

    let failingRequest2 = GraphRequest(graphPath: appID, parameters: parameters, httpMethod: .post)
    XCTAssertFalse(
      GraphRequest.isForFetchingDomainConfiguration(request: failingRequest2),
      "Request is not for fetching the domain configuration. The HTTP Method is wrong"
    )

    let failingRequest3 = GraphRequest(graphPath: "", parameters: parameters, httpMethod: .get)
    XCTAssertFalse(
      GraphRequest.isForFetchingDomainConfiguration(request: failingRequest3),
      "Request is not for fetching the domain configuration. The graph path is wrong"
    )

    let failingRequest4 = GraphRequest(graphPath: appID, parameters: ["fields": "test_field"], httpMethod: .get)
    XCTAssertFalse(
      GraphRequest.isForFetchingDomainConfiguration(request: failingRequest4),
      "Request is not for fetching the domain configuration. The parameters are wrong"
    )

    let failingRequest5 = GraphRequest(
      graphPath: appID,
      parameters: ["fields": "server_domain_infos,test_field,name,app_events_feature_bitmask"],
      httpMethod: .get
    )
    XCTAssertFalse(
      GraphRequest.isForFetchingDomainConfiguration(request: failingRequest5),
      "Request is not for fetching the domain configuration. The parameters are wrong"
    )
  }

  func testSerializeURL() throws {
    let baseURL = try InternalUtility.shared.facebookURL(
      withHostPrefix: prefix,
      path: path,
      queryParameters: [:],
      defaultVersion: version
    )
    let url = GraphRequest.serializeURL(
      baseURL.absoluteString,
      params: parameters,
      httpMethod: HTTPMethod.post.rawValue,
      forBatch: true
    )

    let expectedURL = "https://graph.facebook.com/\(version)/me?fields="
    XCTAssertEqual(url, expectedURL)

    let encodedURL = Utility.encode(urlString: expectedURL)

    XCTAssertEqual(encodedURL, "https%3A%2F%2Fgraph.facebook.com%2F\(version)%2Fme%3Ffields%3D")
    XCTAssertEqual(Utility.decode(urlString: encodedURL), expectedURL)
  }

  func testAttachments() {
    XCTAssertTrue(GraphRequest.isAttachment(UIImage()))
    XCTAssertTrue(GraphRequest.isAttachment(Data()))
    XCTAssertTrue(
      GraphRequest.isAttachment(
        GraphRequestDataAttachment(
          data: Data(),
          filename: "fakefile",
          contentType: "foo"
        )
      )
    )
    XCTAssertFalse(GraphRequest.isAttachment("string"))
    XCTAssertFalse(GraphRequest.isAttachment(Date()))
  }

  func testDebuggingHelpers() {
    let request = GraphRequest(graphPath: path, parameters: parameters, httpMethod: .post)
    let descriptionPart = "graphPath: me, HTTPMethod: POST, parameters: {\n    fields = \"\""
    XCTAssertTrue(
      request.description.contains(descriptionPart),
      "Requests should have useful information in their description"
    )
  }

  func testDebuggingMetadata() {
    let request = GraphRequest(graphPath: path)
    let metadata = GraphRequestMetadata(request: request, completionHandler: nil, batchParameters: [:])
    XCTAssertTrue(
      metadata.description.contains("request: "),
      "Request metadata should include information about the request"
    )
  }

  func testSetSettingsWithCertainVersion() {
    let testVersion = "v123"
    settings.graphAPIVersion = testVersion
    let request = GraphRequest(graphPath: path)
    XCTAssertEqual(request.version, testVersion)
  }

  func testSetSettingsWithGraphErrorRecoveryEnabled() {
    settings.isGraphErrorRecoveryEnabled = true
    let request = GraphRequest(graphPath: path)
    XCTAssertFalse(request.isGraphErrorRecoveryDisabled)
  }

  func testSetSettingsWithDebugParamValue() throws {
    let debugParameter = "TestValue"
    settings.graphAPIDebugParameterValue = debugParameter
    let baseURL = try InternalUtility.shared.facebookURL(
      withHostPrefix: prefix,
      path: path,
      queryParameters: [:],
      defaultVersion: version
    )
    let url = GraphRequest.serializeURL(
      baseURL.absoluteString,
      params: [:],
      httpMethod: HTTPMethod.post.rawValue,
      forBatch: true
    )
    let expectedURL = String(
      format: "https://graph.facebook.com/%@/me?debug=%@",
      version,
      debugParameter
    )

    XCTAssertEqual(url, expectedURL)
  }

  // MARK: - Custom test assertions

  // swiftlint:disable:next function_parameter_count
  static func verifyRequest(
    _ request: GraphRequest,
    expectedGraphPath: String,
    expectedParameters: [String: String],
    expectedTokenString: String?,
    expectedVersion: String,
    expectedMethod: HTTPMethod,
    expectedForAppEvents: Bool = false,
    expectedUseAlternativeValue: Bool = true,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(request.graphPath, expectedGraphPath, file: file, line: line)
    XCTAssertEqual(request.parameters as? [String: String], expectedParameters, file: file, line: line)
    XCTAssertEqual(request.tokenString, expectedTokenString, file: file, line: line)
    XCTAssertEqual(request.version, expectedVersion, file: file, line: line)
    XCTAssertEqual(request.httpMethod, expectedMethod, file: file, line: line)
    XCTAssertEqual(request.forAppEvents, expectedForAppEvents, file: file, line: line)
    XCTAssertEqual(request.useAlternativeDefaultDomainPrefix, expectedUseAlternativeValue, file: file, line: line)
  }
}
