// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import TestTools
import XCTest

final class GraphRequestTests: XCTestCase {

  let path = "me"
  let parameters = ["fields": ""]
  let version = "v11.0"
  let prefix = "graph."
  let settings = TestSettings()

  override func setUp() {
    super.setUp()

    AuthenticationToken.current = nil
    AccessToken.resetCurrentAccessTokenCache()
    GraphRequest.reset()
    GraphRequest.setSettings(settings)
  }

  override func tearDown() {
    GraphRequest.reset()

    super.tearDown()
  }

  // MARK: - Tests

  func testCreatingGraphRequestWithDefaultSessionProxyFactory() {
    let request = GraphRequest(graphPath: path)
    let factory = request.connectionFactory
    XCTAssertTrue(
      factory is GraphRequestConnectionFactory,
      "A graph request should have the correct concrete session provider by default"
    )
  }

  func testCreatingWithCustomUrlSessionProxyFactory() {
    let factory = TestGraphRequestConnectionFactory(stubbedConnection: GraphRequestConnection())
    let request = GraphRequest(
      graphPath: path,
      parameters: nil,
      tokenString: nil,
      httpMethod: nil,
      flags: [],
      connectionFactory: factory
    )

    XCTAssertTrue(
      request.connectionFactory === factory,
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
    let factory = TestGraphRequestConnectionFactory(stubbedConnection: connection)
    let request = GraphRequest(
      graphPath: path,
      parameters: nil,
      tokenString: nil,
      httpMethod: nil,
      flags: [],
      connectionFactory: factory
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

  func testSerializeURL() {
    let baseURL = InternalUtility.shared.facebookURL(
      withHostPrefix: prefix,
      path: path,
      queryParameters: [:],
      defaultVersion: version,
      error: nil
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

  func testCreateRequestWithDefaultTokenString() {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    GraphRequest.setCurrentAccessTokenStringProvider(TestAccessTokenWallet.self)
    let request = GraphRequest(graphPath: path, parameters: [:])
    XCTAssertEqual(
      request.tokenString,
      TestAccessTokenWallet.tokenString,
      "Should use the token string provider for the token string"
    )
    XCTAssertNotNil(request.tokenString, "Should have a concrete token string")
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
    // swiftlint:disable:next force_unwrapping
    let metadata = GraphRequestMetadata(request: request, completionHandler: nil, batchParameters: [:])!
    XCTAssertTrue(
      metadata.description.contains("request: "),
      "Request metadata should include information about the request"
    )
  }

  func testSetSettingsWithCertainVersion() {
    let testVersion = "v123"
    settings.stubbedGraphAPIVersion = testVersion
    let request = GraphRequest(graphPath: path)
    XCTAssertEqual(request.version, testVersion)
  }

  func testSetSettingsWithGraphErrorRecoveryEnabled() {
    settings.isGraphErrorRecoveryEnabled = true
    let request = GraphRequest(graphPath: path)
    XCTAssertFalse(request.isGraphErrorRecoveryDisabled)
  }

  func testSetSettingsWithDebugParamValue() {
    let debugParameter = "TestValue"
    settings.graphAPIDebugParamValue = debugParameter
    let baseURL = InternalUtility.shared.facebookURL(
      withHostPrefix: prefix,
      path: path,
      queryParameters: [:],
      defaultVersion: version,
      error: nil
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
