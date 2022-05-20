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

final class BridgeAPIProtocolWebV2Tests: XCTestCase {

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
    static let bundleIdentifier = "bundle.identifier"
  }

  let validQueryParameters = ["Foo": "Bar"]

  // swiftlint:disable implicitly_unwrapped_optional
  var bridge: BridgeAPIProtocolWebV2!
  var serverConfigurationProvider: ServerConfigurationProviding!
  var nativeBridge: TestBridgeAPIProtocol!
  var errorFactory: ErrorCreating!
  var internalUtility: TestInternalUtility!
  var bundle: TestBundle!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    serverConfigurationProvider = TestServerConfigurationProvider()
    nativeBridge = TestBridgeAPIProtocol()
    errorFactory = TestErrorFactory()
    internalUtility = TestInternalUtility()
    bundle = TestBundle()
    bundle.bundleIdentifier = Values.bundleIdentifier
    bridge = BridgeAPIProtocolWebV2(
      serverConfigurationProvider: serverConfigurationProvider,
      nativeBridge: nativeBridge,
      errorFactory: errorFactory,
      internalUtility: internalUtility,
      infoDictionaryProvider: bundle
    )
  }

  override func tearDown() {
    serverConfigurationProvider = nil
    nativeBridge = nil
    errorFactory = nil
    internalUtility = nil
    bundle = nil
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
    XCTAssertTrue(
      bridge.internalUtility === internalUtility,
      "Should be able to create with a custom internal utility"
    )
    XCTAssertTrue(
      bridge.infoDictionaryProvider === bundle,
      "Should be able to create with a custom info dictionary provider"
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
    XCTAssertTrue(
      bridge.internalUtility === InternalUtility.shared,
      "Should use the expected default internal utility"
    )
    XCTAssertTrue(
      bridge.infoDictionaryProvider === Bundle.main,
      "Should use the expected default info dictionary provider"
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

  func testRequestURLWithUnavailableNativeBridgeURL() {
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

  func testRequestURL() throws {
    let value = UUID().uuidString
    let queryItem = URLQueryItem(name: "somethingUnique", value: value)
    let urlWithParams = SampleURLs.valid(queryItems: [queryItem])
    nativeBridge.stubbedRequestURL = urlWithParams
    stubServerConfigurationWithDialog(
      named: Values.methodName,
      url: urlWithParams
    )

    internalUtility.stubbedAppURL = urlWithParams
    internalUtility.stubbedFacebookURL = urlWithParams

    _ = try? bridge.requestURL(
      withActionID: Values.actionID,
      scheme: URLScheme.https.rawValue,
      methodName: Values.methodName,
      parameters: validQueryParameters
    )

    let queryParameters = try XCTUnwrap(internalUtility.capturedURLQueryParameters)
    XCTAssertEqual(
      queryParameters["somethingUnique"],
      value,
      "The url should contain the query items from the url provided by the native bridge"
    )

    XCTAssertEqual(
      internalUtility.capturedURLHost,
      urlWithParams.host,
      "Should create a url using the host from the dialog configuration"
    )
    XCTAssertEqual(
      internalUtility.capturedURLPath,
      urlWithParams.path,
      "Should create a url using the path from the dialog configuration"
    )

    XCTAssertEqual(
      queryParameters[Keys.iosBundleID],
      bundle.bundleIdentifier,
      "Should add the bundle ID to the query parameters"
    )
    XCTAssertEqual(
      queryParameters[Keys.redirectURL],
      urlWithParams.absoluteString,
      "Should add the redirect url to the query parameters"
    )
  }

  // MARK: - Redirect URL

  func testRedirectURLWithoutActionIdOrMethodName() {
    let appURL = SampleURLs.valid.appendingPathComponent("appURL")
    internalUtility.stubbedAppURL = appURL

    let url = try? bridge._redirectURL(withActionID: nil, methodName: nil)

    let message = "Should create a redirect url without an action identifier and method name using the internal utility"

    XCTAssertEqual(internalUtility.capturedAppURLHost, "bridge", message)
    XCTAssertEqual(internalUtility.capturedAppURLPath, "", message)
    XCTAssertEqual(internalUtility.capturedAppURLQueryParameters, [:], message)
    XCTAssertEqual(url, appURL, message)
  }

  func testRedirectURLWithMethodNameOnly() {
    let appURL = SampleURLs.valid.appendingPathComponent("appURL")
    internalUtility.stubbedAppURL = appURL

    let url = try? bridge._redirectURL(withActionID: nil, methodName: Values.methodName)

    let message = "Should create a redirect url using the method name for the path using the internal utility"

    XCTAssertEqual(internalUtility.capturedAppURLHost, "bridge", message)
    XCTAssertEqual(internalUtility.capturedAppURLPath, Values.methodName, message)
    XCTAssertEqual(internalUtility.capturedAppURLQueryParameters, [:], message)
    XCTAssertEqual(url, appURL, message)
  }

  func testRedirectURLWithActionIdOnly() {
    let appURL = SampleURLs.valid.appendingPathComponent("appURL")
    internalUtility.stubbedAppURL = appURL

    guard
      let url = try? bridge._redirectURL(withActionID: Values.actionID, methodName: nil),
      let bridgeArgsData = try? JSONSerialization.data(withJSONObject: [Keys.actionID: Values.actionID], options: []),
      let bridgeArgsString = String(data: bridgeArgsData, encoding: .utf8)
    else {
      return XCTFail("Should be able to generate test data")
    }

    let message = """
        Should create a redirect url with serialized bridge api arguments that \
        include the action identifier using the internal utility
      """

    XCTAssertEqual(internalUtility.capturedAppURLHost, "bridge", message)
    XCTAssertEqual(internalUtility.capturedAppURLPath, "", message)
    XCTAssertEqual(
      internalUtility.capturedAppURLQueryParameters,
      [Keys.bridgeArgs: bridgeArgsString],
      message
    )
    XCTAssertEqual(url, appURL, message)
  }

  func testRedirectURLWithMethodNameAndActionID() {
    let appURL = SampleURLs.valid.appendingPathComponent("appURL")
    internalUtility.stubbedAppURL = appURL

    guard
      let url = try? bridge._redirectURL(withActionID: Values.actionID, methodName: Values.methodName),
      let bridgeArgsData = try? JSONSerialization.data(withJSONObject: [Keys.actionID: Values.actionID], options: []),
      let bridgeArgsString = String(data: bridgeArgsData, encoding: .utf8)
    else {
      return XCTFail("Should be able to generate test data")
    }

    let message = """
        Should create a redirect url with serialized bridge api arguments that \
        include the action identifier using the internal utility
      """

    XCTAssertEqual(internalUtility.capturedAppURLHost, "bridge", message)
    XCTAssertEqual(internalUtility.capturedAppURLPath, Values.methodName, message)
    XCTAssertEqual(
      internalUtility.capturedAppURLQueryParameters,
      [Keys.bridgeArgs: bridgeArgsString],
      message
    )
    XCTAssertEqual(url, appURL, message)
  }

  // MARK: - Request URL for DialogConfiguration

  func testRequestURLForDialogConfigurationWithoutScheme() throws {
    let facebookURL = SampleURLs.valid.appendingPathComponent("facebook")
    internalUtility.stubbedFacebookURL = facebookURL

    let url = try XCTUnwrap(URL(string: "/"))
    let configuration = DialogConfiguration(name: UUID().uuidString, url: url, appVersions: [])
    let requestURL = try? bridge._requestURL(for: configuration)

    let message = """
      Should provide a request url for a dialog configuration without a scheme \
      using the internal utility
      """

    XCTAssertEqual(internalUtility.capturedFacebookURLHostPrefix, "m", message)
    XCTAssertEqual(internalUtility.capturedFacebookURLPath, "/", message)
    XCTAssertTrue(internalUtility.capturedFacebookURLQueryParameters?.isEmpty ?? false, message)
    XCTAssertEqual(requestURL, facebookURL, message)
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
    let configuration = ServerConfigurationFixtures.configuration(
      withDictionary: ["dialogConfigurations": [name: dialogConfiguration]]
    )
    serverConfigurationProvider = TestServerConfigurationProvider(configuration: configuration)
    bridge = BridgeAPIProtocolWebV2(
      serverConfigurationProvider: serverConfigurationProvider,
      nativeBridge: nativeBridge,
      errorFactory: errorFactory,
      internalUtility: internalUtility,
      infoDictionaryProvider: bundle
    )
  }

  func queryItems(from url: URL) -> [URLQueryItem] {
    URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
  }
}
