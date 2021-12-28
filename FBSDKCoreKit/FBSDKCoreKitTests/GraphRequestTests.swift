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

final class GraphRequestTests: XCTestCase {

  let path = "me"
  let parameters = ["fields": ""]
  let version = "v12.0"
  let prefix = "graph."
  let settings = TestSettings()
  var factory = TestGraphRequestConnectionFactory()

  override func setUp() {
    super.setUp()

    AuthenticationToken.current = nil
    GraphRequest.resetClassDependencies()
    AccessToken.resetCurrentAccessTokenCache()
    TestAccessTokenWallet.reset()

    GraphRequest.configure(
      settings: settings,
      currentAccessTokenStringProvider: TestAccessTokenWallet.self,
      graphRequestConnectionFactory: factory
    )
  }

  override func tearDown() {
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
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
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

  func testDefaultGETParameters() {
    verifyRequest(
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
      GraphRequest(graphPath: path, parameters: [:], tokenString: nil, version: version, httpMethod: .get)
    ]
      .forEach {
        verifyRequest(
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
      GraphRequest(graphPath: path, parameters: parameters, tokenString: nil, version: version, httpMethod: .get)
    ]
      .forEach {
        verifyRequest(
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
    verifyRequest(
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
      GraphRequest(graphPath: path, parameters: [:], tokenString: nil, version: version, httpMethod: .post)
    ]
      .forEach {
        verifyRequest(
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
      GraphRequest(graphPath: path, parameters: parameters, tokenString: nil, version: version, httpMethod: .post)
    ]
      .forEach {
        verifyRequest(
          $0,
          expectedGraphPath: path,
          expectedParameters: parameters,
          expectedTokenString: nil,
          expectedVersion: version,
          expectedMethod: .post
        )
      }
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
    settings.graphAPIDebugParamValue = debugParameter
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
  func verifyRequest(
    _ request: GraphRequest,
    expectedGraphPath: String,
    expectedParameters: [String: String],
    expectedTokenString: String?,
    expectedVersion: String,
    expectedMethod: HTTPMethod,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(request.graphPath, expectedGraphPath, file: file, line: line)
    XCTAssertEqual(request.parameters as? [String: String], expectedParameters, file: file, line: line)
    XCTAssertEqual(request.tokenString, expectedTokenString, file: file, line: line)
    XCTAssertEqual(request.version, expectedVersion, file: file, line: line)
    XCTAssertEqual(request.httpMethod, expectedMethod, file: file, line: line)
  }
}
