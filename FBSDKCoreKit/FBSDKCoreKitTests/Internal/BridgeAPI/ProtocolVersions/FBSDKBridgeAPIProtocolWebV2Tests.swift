/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class FBSDKBridgeAPIProtocolWebV2Tests: XCTestCase {

  enum Keys {
    static let actionID = "action_id"
    static let bridgeArgs = "bridge_args"
    static let redirectURL = "redirect_url"
    static let iosBundleID = "ios_bundle_id"
  }

  enum Values {
    static let actionID = "123"
    static let methodName = "open"
    static let scheme = URLScheme.https
  }

  let validQueryParameters = ["Foo": "Bar"]

  // swiftlint:disable implicitly_unwrapped_optional
  var serverConfigurationProvider: ServerConfigurationProviding!
  var nativeBridge: TestBridgeAPIProtocol!
  var errorFactory: ErrorCreating!
  var bridge: BridgeAPIProtocolWebV2!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    serverConfigurationProvider = TestServerConfigurationProvider()
    nativeBridge = TestBridgeAPIProtocol()
    errorFactory = TestErrorFactory()
    bridge = BridgeAPIProtocolWebV2(
      serverConfigurationProvider: serverConfigurationProvider,
      nativeBridge: nativeBridge,
      errorFactory: errorFactory
    )
  }

  override func tearDown() {
    serverConfigurationProvider = nil
    nativeBridge = nil
    errorFactory = nil
    bridge = nil

    super.tearDown()
  }

  func testInitializing() {
    XCTAssertTrue(
      bridge.serverConfigurationProvider is TestServerConfigurationProvider,
      "Should be able to create with a custom server configuration provider"
    )
    XCTAssertTrue(
      bridge.nativeBridge === nativeBridge,
      "Should be able to create with a custom native bridge"
    )
    XCTAssertTrue(
      bridge.errorFactory === errorFactory,
      "Should be able to create with a custom error factory"
    )
  }

  func testDefaultDependencies() throws {
    bridge = BridgeAPIProtocolWebV2()

    XCTAssertTrue(
      bridge.serverConfigurationProvider is ServerConfigurationManager,
      "Should use the expected default server configuration provider"
    )
    XCTAssertTrue(
      bridge.nativeBridge is BridgeAPIProtocolNativeV1,
      "Should use the expected default native bridge"
    )
    let factory = try XCTUnwrap(
      bridge.errorFactory as? ErrorFactory,
      "Should use the expected type of error factory by default"
    )
    XCTAssertTrue(
      factory.reporter === ErrorReporter.shared,
      "The error factory should use the shared error reporter"
    )
  }

  // MARK: - Request URL

  func testRequestURLWithoutServerConfiguration() {
    XCTAssertNil(
      try? bridge.requestURL(
        withActionID: "",
        scheme: "",
        methodName: "",
        parameters: [:]
      ),
      "Should not create a url without a server configuration"
    )
  }

  func testRequestURLWithoutDialog() {
    let url = try? bridge.requestURL(
      withActionID: "",
      scheme: "",
      methodName: "Foo",
      parameters: [:]
    )

    XCTAssertNil(
      url,
      "Should not create a url if the server configuration does not provide a dialog"
    )
  }

  func testRequestURLWithoutMatchingDialogForMethodName() {
    stubServerConfigurationWithDialog(named: "Bar")
    let url = try? bridge.requestURL(
      withActionID: "",
      scheme: "",
      methodName: "Foo",
      parameters: [:]
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
      withActionID: "",
      scheme: "",
      methodName: Values.methodName,
      parameters: [:]
    )

    XCTAssertNil(
      url,
      "Should not create a url if the native bridge cannot provide one"
    )
  }

  func testRequestUrlUsesQueryParametersFromNativeBridge() {
    let queryItem = URLQueryItem(name: "somethingUnique", value: UUID().uuidString)
    let urlWithParams = SampleURLs.valid(queryItems: [queryItem])
    nativeBridge.stubbedRequestURL = urlWithParams
    stubServerConfigurationWithDialog(
      named: Values.methodName
    )

    guard let url = try? bridge.requestURL(
      withActionID: Values.actionID,
      scheme: URLScheme.https.rawValue,
      methodName: Values.methodName,
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
    let expectedURL = SampleURLs.valid(path: "foo")
    stubServerConfigurationWithDialog(
      named: Values.methodName,
      url: expectedURL
    )
    guard let url = try? bridge.requestURL(
      withActionID: Values.actionID,
      scheme: Values.scheme.rawValue,
      methodName: Values.methodName,
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
    guard
      let url = try? bridge._redirectURL(withActionID: name, methodName: nil),
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
    guard
      let url = try? bridge._redirectURL(withActionID: name, methodName: Values.methodName),
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

  func testRequestURLForDialogConfigurationWithoutScheme() throws {
    let url = try XCTUnwrap(URL(string: "/"))
    let configuration = DialogConfiguration(name: name, url: url, appVersions: [])
    let requestURL = try? bridge._requestURL(for: configuration)

    XCTAssertEqual(
      requestURL?.absoluteString,
      "https://m.facebook.com/\(Settings.shared.graphAPIVersion)/",
      "Should provide a request url for a dialog configuration without a scheme"
    )
  }

  func testRequestURLForDialogConfigurationWithScheme() {
    let configuration = DialogConfiguration(
      name: name,
      url: SampleURLs.valid(path: name),
      appVersions: []
    )
    let requestURL = try? bridge._requestURL(for: configuration)

    XCTAssertEqual(
      requestURL?.absoluteString,
      SampleURLs.valid(path: name).absoluteString,
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
    guard
      let parameters = nativeBridge.capturedResponseQueryParameters as? [String: String],
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
    url: URL = SampleURLs.valid
  ) {
    let dialogConfiguration = DialogConfiguration(
      name: name,
      url: url,
      appVersions: []
    )
    let configuration = ServerConfigurationFixtures.config(
      withDictionary: ["dialogConfigurations": [name: dialogConfiguration]]
    )
    serverConfigurationProvider = TestServerConfigurationProvider(configuration: configuration)
    bridge = BridgeAPIProtocolWebV2(
      serverConfigurationProvider: serverConfigurationProvider,
      nativeBridge: nativeBridge,
      errorFactory: errorFactory
    )
  }

  func queryItems(from url: URL) -> [URLQueryItem] {
    URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
  }
}
