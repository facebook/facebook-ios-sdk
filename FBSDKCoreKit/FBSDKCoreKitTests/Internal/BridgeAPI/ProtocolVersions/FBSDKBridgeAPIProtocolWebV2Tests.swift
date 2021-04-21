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

import XCTest

// swiftlint:disable type_body_length
class FBSDKBridgeAPIProtocolWebV2Tests: FBSDKTestCase {

  enum Keys {
    static let actionID = "action_id"
    static let bridgeArgs = "bridge_args"
    static let redirectURL = "redirect_url"
    static let iosBundleID = "ios_bundle_id"
  }

  enum Values {
    static let actionID = "123"
    static let methodName = "open"
    static let methodVersion = "v1"
    static let scheme = "https"
  }

  let validQueryParameters = ["Foo": "Bar"]
  var bridge: BridgeAPIProtocolWebV2! // swiftlint:disable:this implicitly_unwrapped_optional
  var nativeBridge = TestBridgeApiProtocol()

  override func setUp() {
    super.setUp()

    TestServerConfigurationProvider.reset()

    bridge = BridgeAPIProtocolWebV2(
      serverConfigurationProvider: TestServerConfigurationProvider.self,
      nativeBridge: nativeBridge
    )
  }

  override class func tearDown() {
    super.tearDown()

    TestServerConfigurationProvider.reset()
  }

  func testDefaultDependencies() {
    bridge = BridgeAPIProtocolWebV2()

    XCTAssertTrue(
      bridge.serverConfigurationProvider is ServerConfigurationManager.Type,
      "Should use the expected default server configuration provider"
    )
    XCTAssertTrue(
      bridge.nativeBridge is BridgeAPIProtocolNativeV1,
      "Should use the expected default native bridge"
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertTrue(
      bridge.serverConfigurationProvider is TestServerConfigurationProvider.Type,
      "Should be able to create with a custom server configuration provider"
    )
    XCTAssertEqual(
      bridge.nativeBridge as? TestBridgeApiProtocol,
      nativeBridge,
      "Should be able to create with a custom native bridge"
    )
  }

  // MARK: - Request URL

  func testRequestURLWithoutServerConfiguration() {
    XCTAssertNil(
      try? bridge.requestURL(
        withActionID: nil,
        scheme: nil,
        methodName: nil,
        methodVersion: nil,
        parameters: nil
      ),
      "Should not create a url without a server configuration"
    )
  }

  func testRequestURLWithoutDialog() {
    TestServerConfigurationProvider.stubbedServerConfiguration = ServerConfigurationFixtures.defaultConfig()
    let url = try? bridge.requestURL(
      withActionID: nil,
      scheme: nil,
      methodName: "Foo",
      methodVersion: nil,
      parameters: nil
    )

    XCTAssertNil(
      url,
      "Should not create a url if the server configuration does not provide a dialog"
    )
  }

  func testRequestURLWithoutMatchingDialogForMethodName() {
    stubServerConfigurationWithDialog(named: "Bar")
    let url = try? bridge.requestURL(
      withActionID: nil,
      scheme: nil,
      methodName: "Foo",
      methodVersion: nil,
      parameters: nil
    )

    XCTAssertNil(
      url,
      "Should not create a url if the server configuration does not provide a dialog matching the method name"
    )
  }

  func testRequestURLWithUnavailableNativeBridgeUrl() {
    stubServerConfigurationWithDialog(named: Values.methodName)
    nativeBridge.stubbedRequestURLError = SampleError()
    let url = try? bridge.requestURL(
      withActionID: nil,
      scheme: nil,
      methodName: Values.methodName,
      methodVersion: nil,
      parameters: nil
    )

    XCTAssertNil(
      url,
      "Should not create a url if the native bridge cannot provide one"
    )
  }

  func testRequestUrlUsesQueryParametersFromNativeBridge() {
    let queryItem = URLQueryItem(name: "somethingUnique", value: UUID().uuidString)
    let urlWithParams = SampleUrls.valid(queryItems: [queryItem])
    nativeBridge.stubbedRequestURL = urlWithParams
    stubServerConfigurationWithDialog(
      named: Values.methodName
    )

    guard let url = try? bridge.requestURL(
      withActionID: Values.actionID,
      scheme: Values.scheme,
      methodName: Values.methodName,
      methodVersion: Values.methodVersion,
      parameters: validQueryParameters
    )
    else {
      return XCTFail("Should create a valid url")
    }

    guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
    else {
      return XCTFail("Should have query items")
    }
    XCTAssertTrue(
      queryItems.contains(queryItem),
      "The url should contain the query items from the url provided by the native bridge"
    )
  }

  func testRequestURL() {
    let expectedURL = SampleUrls.valid(path: "foo")
    stubServerConfigurationWithDialog(
      named: Values.methodName,
      url: expectedURL
    )
    guard let url = try? bridge.requestURL(
      withActionID: Values.actionID,
      scheme: Values.scheme,
      methodName: Values.methodName,
      methodVersion: Values.methodVersion,
      parameters: validQueryParameters
    )
    else {
      return XCTFail("Should create a valid url")
    }

    XCTAssertEqual(
      url.host,
      expectedURL.host,
      "Should create a url using the host from the dialog configuration"
    )
    XCTAssertEqual(
      url.path,
      expectedURL.path,
      "Should create a url using the path from the dialog configuration"
    )

    let items = queryItems(from: url)
    XCTAssertTrue(
      items.contains(
        URLQueryItem(name: Keys.iosBundleID, value: Bundle.main.bundleIdentifier)
      ),
      "Should add the bundle ID to the query parameters"
    )
    XCTAssertTrue(
      items.contains(
        URLQueryItem(name: Keys.redirectURL, value: "fb://bridge/open")
      ),
      "Should add the redirect url to the query parameters"
    )
  }

  // MARK: - Redirect URL

  func testRedirectUrlWithoutActionIdOrMethodName() {
    let url = try? bridge._redirectURL(withActionID: nil, methodName: nil)
    XCTAssertEqual(
      url?.absoluteString,
      "fb://bridge/",
      "Should create a redirect url without an action identifier and method name"
    )
  }

  func testRedirectUrlWithMethodNameOnly() {
    let url = try? bridge._redirectURL(withActionID: nil, methodName: Values.methodName)

    XCTAssertEqual(
      url?.absoluteString,
      "fb://bridge/\(Values.methodName)",
      "Should create a redirect url using the method name for the path"
    )
  }

  func testRedirectUrlWithActionIdOnly() {
    guard let url = try? bridge._redirectURL(withActionID: name, methodName: nil),
          let bridgeArgsData = try? JSONSerialization.data(withJSONObject: [Keys.actionID: name], options: []),
          let bridgeArgsString = String(data: bridgeArgsData, encoding: .utf8)
    else {
      return XCTFail("Should be able to generate test data")
    }

    XCTAssertEqual(
      url.scheme,
      "fb",
      "Should create a redirect url with the expected scheme"
    )
    XCTAssertEqual(
      url.host,
      "bridge",
      "Should create a redirect url with the expected host"
    )
    XCTAssertTrue(
      queryItems(from: url).contains(
        URLQueryItem(name: Keys.bridgeArgs, value: bridgeArgsString)
      ),
      "Should create a redirect url with serialized bridge api arguments that include the action identifier"
    )
  }

  func testRedirectUrlWithMethodNameAndActionID() {
    guard let url = try? bridge._redirectURL(withActionID: name, methodName: Values.methodName),
          let bridgeArgsData = try? JSONSerialization.data(withJSONObject: [Keys.actionID: name], options: []),
          let bridgeArgsString = String(data: bridgeArgsData, encoding: .utf8)
    else {
      return XCTFail("Should be able to generate test data")
    }

    XCTAssertEqual(
      url.scheme,
      "fb",
      "Should create a redirect url with the expected scheme"
    )
    XCTAssertEqual(
      url.host,
      "bridge",
      "Should create a redirect url with the expected host"
    )
    XCTAssertEqual(
      url.path,
      "/" + Values.methodName,
      "Should create a redirect url using the method name for the path"
    )
    XCTAssertTrue(
      queryItems(from: url).contains(
        URLQueryItem(name: Keys.bridgeArgs, value: bridgeArgsString)
      ),
      "Should create a redirect url with serialized bridge api arguments that include the action identifier"
    )
  }

  // MARK: - Request URL for DialogConfiguration

  func testRequestURLForDialogConfigurationWithoutScheme() {
    guard let url = URL(string: "/"),
          let configuration = DialogConfiguration(
            name: name,
            url: url,
            appVersions: []
          ),
          let requestURL = try? bridge._requestURL(for: configuration),
          let version = Settings.graphAPIVersion
    else {
      return XCTFail("Should be able to create a configuration with a url")
    }

    XCTAssertEqual(
      requestURL.absoluteString,
      "https://m.facebook.com/\(version)/",
      "Should provide a request url for a dialog configuration without a scheme"
    )
  }

  func testRequestURLForDialogConfigurationWithScheme() {
    guard let configuration = DialogConfiguration(
            name: name,
            url: SampleUrls.valid(path: name),
            appVersions: []
          ),
          let requestURL = try? bridge._requestURL(for: configuration)
    else {
      return XCTFail("Should be able to create a configuration with a url")
    }

    XCTAssertEqual(
      requestURL.absoluteString,
      SampleUrls.valid(path: name).absoluteString,
      "Should use the url from the dialog configuration if it has a scheme"
    )
  }

  // MARK: - Response Parameters

  func testResponseParameters() {
    var isCancelled = ObjCBool(false)
    _ = try? bridge.responseParameters(
      forActionID: Values.actionID,
      queryParameters: validQueryParameters,
      cancelled: &isCancelled
    )
    XCTAssertEqual(
      nativeBridge.capturedResponseActionID,
      Values.actionID,
      "Should pass through to the native bridge"
    )
    guard let parameters = nativeBridge.capturedResponseQueryParameters as? [String: String],
          parameters == validQueryParameters
    else {
      return XCTFail("Should pass through to the native bridge")
    }

    XCTAssertNotNil(
      nativeBridge.capturedResponseCancelledRef,
      "Should pass through to the native bridge"
    )
  }

  // MARK: - Helpers

  func stubServerConfigurationWithDialog(
    named name: String,
    url: URL = SampleUrls.valid
  ) {
    let dialogConfiguration = DialogConfiguration(
      name: name,
      url: url,
      appVersions: []
    )
    let configuration = ServerConfigurationFixtures.config(with: ["dialogConfigurations": [name: dialogConfiguration]])
    TestServerConfigurationProvider.stubbedServerConfiguration = configuration
  }

  func queryItems(from url: URL) -> [URLQueryItem] {
    return URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
  }
}
