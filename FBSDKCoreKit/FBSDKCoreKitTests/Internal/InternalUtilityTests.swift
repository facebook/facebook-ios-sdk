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

class InternalUtilityTests: XCTestCase {

  let validParameters = ["foo": "bar"]
  let validPath = "example"
  let facebookUrlSchemeMissingMessage = "fbapi is missing from your Info.plist under LSApplicationQueriesSchemes and is required." // swiftlint:disable:this line_length
  let messengerUrlSchemeMissingMessage = "fb-messenger-share-api is missing from your Info.plist under LSApplicationQueriesSchemes and is required." // swiftlint:disable:this line_length
  let dialogURL = URL(
    string: "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)/dialog"
  )! // swiftlint:disable:this force_unwrapping
  let nonDialogURL = URL(
    string: "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)/foo"
  )! // swiftlint:disable:this force_unwrapping

  // swiftlint:disable implicitly_unwrapped_optional
  var bundle: TestBundle!
  var loggerFactory: TestLoggerFactory!
  var logger: TestLogger!
  var settings: TestSettings!
  // swiftlint:enable implicitly_unwrapped_optional force_unwrapping

  override func setUp() {
    super.setUp()

    InternalUtility.reset()

    bundle = TestBundle()
    loggerFactory = TestLoggerFactory()
    logger = TestLogger(loggingBehavior: .developerErrors)
    loggerFactory.logger = logger
    settings = TestSettings()

    InternalUtility.shared.deleteFacebookCookies()
    InternalUtility.reset()
    configureInternalUtility()
  }

  override func tearDown() {
    InternalUtility.reset()

    bundle = nil
    loggerFactory = nil
    logger = nil
    settings = nil

    super.tearDown()
  }

  func configureInternalUtility() {
    InternalUtility.shared.configure(
      withInfoDictionaryProvider: bundle,
      loggerFactory: loggerFactory,
      settings: settings
    )
  }

  func testDefaultDependencies() {
    InternalUtility.reset()

    XCTAssertNil(
      InternalUtility.shared.infoDictionaryProvider,
      "Should not have an info dictionary provider by default"
    )
    XCTAssertNil(
      InternalUtility.shared.loggerFactory,
      "Should not have a logger factory by default"
    )
    XCTAssertNil(
      InternalUtility.shared.settings,
      "Should not have settings by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      InternalUtility.shared.infoDictionaryProvider === bundle,
      "Should be able to provide an info dictionary provider"
    )
    XCTAssertTrue(
      InternalUtility.shared.loggerFactory === loggerFactory,
      "The shared instance should use the provided logger factory"
    )
    XCTAssertTrue(
      InternalUtility.shared.settings === settings,
      "The shared instance should use the provided settings"
    )
  }

  func testFacebookURL() throws {
    settings.facebookDomainPart = ""
    var urlString = ""

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "",
      path: "",
      queryParameters: [:]
    ).absoluteString

    XCTAssertEqual(urlString, "https://facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m.",
      path: "",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/dialog/share",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)/dialog/share")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "dialog/share",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)/dialog/share")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "dialog/share",
      queryParameters: ["key": "value"]
    ).absoluteString
    XCTAssertEqual(
      urlString,
      "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)/dialog/share?key=value"
    )

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/v1.0/dialog/share",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/v1.0/dialog/share")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/dialog/share",
      queryParameters: [:],
      defaultVersion: "v2.0"
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/v2.0/dialog/share")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/v1.0/dialog/share",
      queryParameters: [:],
      defaultVersion: "v2.0"
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/v1.0/dialog/share")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/v987654321.2/dialog/share",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/v987654321.2/dialog/share")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/v.1/dialog/share",
      queryParameters: [:],
      defaultVersion: "v2.0"
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/v2.0/v.1/dialog/share")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/v1/dialog/share",
      queryParameters: [:],
      defaultVersion: "v2.0"
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/v2.0/v1/dialog/share")

    settings.graphAPIVersion = "v3.3"
    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/v1/dialog/share",
      queryParameters: [:],
      defaultVersion: ""
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/v3.3/v1/dialog/share")

    settings.graphAPIVersion = FBSDK_DEFAULT_GRAPH_API_VERSION
    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/dialog/share",
      queryParameters: [:],
      defaultVersion: ""
    ).absoluteString
    XCTAssertEqual(urlString, "https://m.facebook.com/\(FBSDK_DEFAULT_GRAPH_API_VERSION)/dialog/share")
  }

  func testFacebookGamingURL() throws {
    settings.facebookDomainPart = ""
    let authToken = AuthenticationToken(
      tokenString: "token_string",
      nonce: "nonce",
      graphDomain: "gaming"
    )
    AuthenticationToken.current = authToken

    var urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "graph",
      path: "",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://graph.fb.gg/\(FBSDK_DEFAULT_GRAPH_API_VERSION)")

    urlString = try InternalUtility.shared.facebookURL(
      withHostPrefix: "graph-video",
      path: "",
      queryParameters: [:]
    ).absoluteString
    XCTAssertEqual(urlString, "https://graph-video.fb.gg/\(FBSDK_DEFAULT_GRAPH_API_VERSION)")
  }

  // MARK: - Extracting Permissions

  func testParsingPermissionsWithFuzzyValues() {
    // A lack of a runtime crash is considered a success here.
    (1 ... 100).forEach { _ in
      InternalUtility.shared.extractPermissions(
        fromResponse: SampleRawRemotePermissionList.randomValues,
        grantedPermissions: [],
        declinedPermissions: [],
        expiredPermissions: []
      )
    }
  }

  func testExtractingPermissionsFromResponseWithInvalidTopLevelKey() {
    let grantedPermissions = NSMutableSet()
    let declinedPermissions = NSMutableSet()
    let expiredPermissions = NSMutableSet()

    InternalUtility.shared.extractPermissions(
      fromResponse: SampleRawRemotePermissionList.missingTopLevelKey,
      grantedPermissions: grantedPermissions,
      declinedPermissions: declinedPermissions,
      expiredPermissions: expiredPermissions
    )
    XCTAssertEqual(grantedPermissions.count, 0, "Should not add granted permissions if top level key is missing")
    XCTAssertEqual(declinedPermissions.count, 0, "Should not add declined permissions if top level key is missing")
    XCTAssertEqual(expiredPermissions.count, 0, "Should not add expired permissions if top level key is missing")
  }

  func testExtractingPermissionsFromResponseWithMissingPermissions() {
    let grantedPermissions = NSMutableSet()
    let declinedPermissions = NSMutableSet()
    let expiredPermissions = NSMutableSet()

    InternalUtility.shared.extractPermissions(
      fromResponse: SampleRawRemotePermissionList.missingPermissions,
      grantedPermissions: grantedPermissions,
      declinedPermissions: declinedPermissions,
      expiredPermissions: expiredPermissions
    )
    XCTAssertEqual(grantedPermissions.count, 0, "Should not add missing granted permissions")
    XCTAssertEqual(declinedPermissions.count, 0, "Should not add missing declined permissions")
    XCTAssertEqual(expiredPermissions.count, 0, "Should not add missing expired permissions")
  }

  func testExtractingPermissionsFromResponseWithMissingStatus() {
    let grantedPermissions = NSMutableSet()
    let declinedPermissions = NSMutableSet()
    let expiredPermissions = NSMutableSet()

    InternalUtility.shared.extractPermissions(
      fromResponse: SampleRawRemotePermissionList.missingStatus,
      grantedPermissions: grantedPermissions,
      declinedPermissions: declinedPermissions,
      expiredPermissions: expiredPermissions
    )
    XCTAssertEqual(grantedPermissions.count, 0, "Should not add a permission with a missing status")
    XCTAssertEqual(declinedPermissions.count, 0, "Should not add a permission with a missing status")
    XCTAssertEqual(expiredPermissions.count, 0, "Should not add a permission with a missing status")
  }

  func testExtractingPermissionsFromResponseWithValidPermissions() {
    let grantedPermissions = NSMutableSet()
    let declinedPermissions = NSMutableSet()
    let expiredPermissions = NSMutableSet()

    InternalUtility.shared.extractPermissions(
      fromResponse: SampleRawRemotePermissionList.validAllStatuses,
      grantedPermissions: grantedPermissions,
      declinedPermissions: declinedPermissions,
      expiredPermissions: expiredPermissions
    )
    XCTAssertEqual(grantedPermissions.count, 1, "Should add granted permissions when available")
    XCTAssertTrue(grantedPermissions.contains("email"), "Should add the correct permission to granted permissions")

    XCTAssertEqual(declinedPermissions.count, 1, "Should add declined permissions when available")
    XCTAssertTrue(declinedPermissions.contains("birthday"), "Should add the correct permission to declined permissions")

    XCTAssertEqual(expiredPermissions.count, 1, "Should add expired permissions when available")
    XCTAssertTrue(expiredPermissions.contains("first_name"), "Should add the correct permission to expired permissions")
  }

  // MARK: - Can open URL scheme

  func testCanOpenUrlSchemeWithMissingScheme() {
    XCTAssertFalse(
      InternalUtility.shared._canOpenURLScheme(nil),
      "Should not be able to open a missing scheme"
    )

    XCTAssertNil(logger.capturedContents, "A developer error should not be logged for a nil scheme")
  }

  func testCanOpenUrlSchemeWithInvalidSchemes() {
    [
      "http: ",
      "",
      "   ",
      "#@%(*&#$(^#@!$",
      "////foo",
      "foo: ",
      "foo: /"
    ]
      .forEach { invalidScheme in
        InternalUtility.shared._canOpenURLScheme(invalidScheme)

        verifyTestLoggerInvoked(
          loggingBehavior: .developerErrors,
          logEntry: "Invalid URL scheme provided: \(invalidScheme)"
        )
      }
  }

  func testCanOpenUrlSchemeWithValidSchemes() {
    [
      "foo",
      "FOO",
      "foo+bar",
      "foo-bar",
      "foo.bar"
    ]
      .forEach { validScheme in
        InternalUtility.shared._canOpenURLScheme(validScheme)
        XCTAssertNil(logger.capturedContents, "A developer error should not be logged for valid schemes")
      }
  }

  // MARK: - App URL Scheme

  func testAppURLSchemeWithMissingAppIdMissingSuffix() {
    settings.appID = nil
    settings.appURLSchemeSuffix = nil
    // This is not desired behavior but accurately reflects what is currently written.
    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      "fb",
      "Should return an app url scheme derived from the app id and app url scheme suffix"
    )
  }

  func testAppURLSchemeWithMissingAppIdInvalidSuffix() {
    settings.appID = nil
    settings.appURLSchemeSuffix = "   "
    // This is not desired behavior but accurately reflects what is currently written.
    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      "fb   ",
      "Should return an app url scheme derived from the app id and app url scheme suffix"
    )
  }

  func testAppURLSchemeWithMissingAppIdValidSuffix() {
    settings.appID = nil
    settings.appURLSchemeSuffix = "foo"
    // This is not desired behavior but accurately reflects what is currently written.
    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      "fbfoo",
      "Should return an app url scheme derived from the app id and app url scheme suffix"
    )
  }

  func testAppURLSchemeWithInvalidAppIdMissingSuffix() {
    let appID = " "
    settings.appID = appID
    settings.appURLSchemeSuffix = nil
    let expected = "fb\(appID)"

    // This is not desired behavior but accurately reflects what is currently written.
    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      expected,
      "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
    )
  }

  func testAppURLSchemeWithInvalidAppIdInvalidSuffix() {
    let appID = " "
    let suffix = " "
    settings.appID = appID
    settings.appURLSchemeSuffix = suffix
    let expected = "fb\(appID)\(suffix)"

    // This is not desired behavior but accurately reflects what is currently written.
    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      expected,
      "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
    )
  }

  func testAppURLSchemeWithInvalidAppIdValidSuffix() {
    let appID = " "
    let suffix = "foo"
    settings.appID = appID
    settings.appURLSchemeSuffix = suffix
    let expected = "fb\(appID)\(suffix)"

    // This is not desired behavior but accurately reflects what is currently written.
    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      expected,
      "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
    )
  }

  func testAppURLSchemeWithValidAppIdMissingSuffix() {
    let appID = "appid"
    settings.appID = appID
    settings.appURLSchemeSuffix = nil
    let expected = "fb\(appID)"

    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      expected,
      "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
    )
  }

  func testAppURLSchemeWithValidAppIdInvalidSuffix() {
    let appID = "appid"
    let suffix = "   "
    settings.appID = appID
    settings.appURLSchemeSuffix = suffix
    let expected = "fb\(appID)\(suffix)"

    // This is not desired behavior but accurately reflects what is currently written.
    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      expected,
      "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
    )
  }

  func testAppURLSchemeWithValidAppIdValidSuffix() {
    let appID = "appid"
    let suffix = "foo"
    settings.appID = appID
    settings.appURLSchemeSuffix = suffix
    let expected = "fb\(appID)\(suffix)"

    XCTAssertEqual(
      InternalUtility.shared.appURLScheme,
      expected,
      "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
    )
  }

  // MARK: - App URL with host

  func testAppUrlWithEmptyHost() throws {
    settings.appID = "appid"
    settings.appURLSchemeSuffix = "foo"

    let url = try InternalUtility.shared.appURL(
      withHost: "",
      path: validPath,
      queryParameters: validParameters
    )

    XCTAssertNil(url.host, "Should not set an empty host.")
  }

  func testAppUrlWithValidHost() throws {
    settings.appID = "appid"
    settings.appURLSchemeSuffix = "foo"

    let url = try InternalUtility.shared.appURL(
      withHost: "facebook",
      path: validPath,
      queryParameters: validParameters
    )

    XCTAssertEqual(url.host, "facebook", "Should set the expected host.")
  }

  // MARK: - Check registered can open url scheme

  func testCheckRegisteredCanOpenURLScheme() {
    let scheme = "foo"

    InternalUtility.shared.checkRegisteredCanOpenURLScheme(scheme)

    verifyTestLoggerInvoked(
      loggingBehavior: .developerErrors,
      logEntry: "\(scheme) is missing from your Info.plist under LSApplicationQueriesSchemes and is required."
    )
  }

  func testCheckRegisteredCanOpenURLSchemeMultipleTimes() {
    let scheme = "foo"

    XCTAssertEqual(logger.logEntryCallCount, 0, "There should not be developer errors logged initially")

    InternalUtility.shared.checkRegisteredCanOpenURLScheme(scheme)

    XCTAssertEqual(logger.logEntryCallCount, 1, "One developer error should be logged")
    verifyTestLoggerInvoked(
      loggingBehavior: .developerErrors,
      logEntry: "\(scheme) is missing from your Info.plist under LSApplicationQueriesSchemes and is required."
    )

    InternalUtility.shared.checkRegisteredCanOpenURLScheme(scheme)
    XCTAssertEqual(logger.logEntryCallCount, 1, "Additional errors should not be logged for the same error")
  }

  // MARK: - Dictionary from FBURL

  func testWithAuthorizeHostNoParameters() throws {
    let url = try XCTUnwrap(URL(string: "foo://authorize"))
    let parameters = InternalUtility.shared.parameters(fromFBURL: url)

    XCTAssertTrue(
      parameters.isEmpty,
      "Should not extract parameters from a url if there are none"
    )
  }

  func testWithAuthorizeHostNoFragment() throws {
    let url = try XCTUnwrap(URL(string: "foo://authorize?foo=bar"))
    let parameters = InternalUtility.shared.parameters(fromFBURL: url) as? [String: String]

    XCTAssertEqual(
      parameters,
      ["foo": "bar"],
      "Should extract parameters from a url"
    )
  }

  func testWithAuthorizeHostAndFragment() throws {
    let url = try XCTUnwrap(URL(string: "foo://authorize?foo=bar#param1=value1&param2=value2"))
    let parameters = InternalUtility.shared.parameters(fromFBURL: url) as? [String: String]
    let expectedParameters = [
      "foo": "bar",
      "param1": "value1",
      "param2": "value2"
    ]

    XCTAssertEqual(
      parameters,
      expectedParameters,
      "Extracted parameters from an auth url should include fragment parameters"
    )
  }

  func testWithoutAuthorizeHostNoParameters() throws {
    let url = try XCTUnwrap(URL(string: "foo://example"))
    let parameters = InternalUtility.shared.parameters(fromFBURL: url)

    XCTAssertTrue(
      parameters.isEmpty,
      "Should not extract parameters from a url if there are none"
    )
  }

  func testWithoutAuthorizeHostNoFragment() throws {
    let url = try XCTUnwrap(URL(string: "foo://example?foo=bar"))
    let parameters = InternalUtility.shared.parameters(fromFBURL: url) as? [String: String]

    XCTAssertEqual(
      parameters,
      ["foo": "bar"],
      "Should extract parameters from a url"
    )
  }

  func testWithoutAuthorizeHostWithFragment() throws {
    let url = try XCTUnwrap(URL(string: "foo://example?foo=bar#param1=value1&param2=value2"))
    let parameters = InternalUtility.shared.parameters(fromFBURL: url) as? [String: String]

    XCTAssertEqual(
      parameters,
      ["foo": "bar"],
      "Extracted parameters from a non auth url should not include fragment parameters"
    )
  }

  // MARK: - Cookies

  func testDeletingDialogCookies() {
    let cookie1 = makeCookie(url: dialogURL)
    let cookie2 = makeCookie(url: dialogURL, name: "cookie 2")

    HTTPCookieStorage.shared.setCookie(cookie1)
    HTTPCookieStorage.shared.setCookie(cookie2)

    let cookies = HTTPCookieStorage.shared.cookies(for: dialogURL)
    let expectedCookies = [cookie1, cookie2]

    XCTAssertEqual(cookies, expectedCookies, "Sanity check that there are cookies to delete")

    InternalUtility.shared.deleteFacebookCookies()
    XCTAssertEqual(
      HTTPCookieStorage.shared.cookies(for: dialogURL),
      [],
      "All cookies for the facebook dialog url should be deleted"
    )
  }

  func testDeletingNonDialogCookies() {
    let cookie = makeCookie(url: nonDialogURL)
    HTTPCookieStorage.shared.setCookie(cookie)

    let cookies = HTTPCookieStorage.shared.cookies(for: nonDialogURL)
    XCTAssertEqual(cookies, [cookie], "Sanity check that there are cookies to delete")

    InternalUtility.shared.deleteFacebookCookies()
    XCTAssertEqual(
      HTTPCookieStorage.shared.cookies(for: nonDialogURL),
      [cookie],
      "Should only delete cookies for the dialog url"
    )
  }

  func testDeletingMixOfCookies() {
    let dialogCookie = makeCookie(url: dialogURL)
    let nonDialogCookie = makeCookie(url: nonDialogURL)

    HTTPCookieStorage.shared.setCookie(dialogCookie)
    HTTPCookieStorage.shared.setCookie(nonDialogCookie)

    InternalUtility.shared.deleteFacebookCookies()

    XCTAssertEqual(
      HTTPCookieStorage.shared.cookies(for: dialogURL),
      [],
      "Should delete cookies for the dialog url"
    )
    XCTAssertEqual(
      HTTPCookieStorage.shared.cookies(for: nonDialogURL),
      [nonDialogCookie],
      "Should only delete cookies for the dialog url"
    )
  }

  // MARK: - App Installation

  func testIsRegisteredCanOpenURLSchemeWithMissingScheme() {
    let querySchemes = [String]()
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertFalse(
      InternalUtility.shared.isRegisteredCanOpenURLScheme(name),
      "Should not be consider a scheme to be registered if it's missing from the application query schemes"
    )
  }

  func testIsRegisteredCanOpenURLSchemeWithScheme() {
    let querySchemes = [name]
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertTrue(
      InternalUtility.shared.isRegisteredCanOpenURLScheme(name),
      "Should consider a scheme to be registered if it exists in the application query schemes"
    )
  }

  func testIsRegisteredCanOpenURLSchemeCache() {
    let querySchemes = [name]
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertTrue(InternalUtility.shared.isRegisteredCanOpenURLScheme(name), "Sanity check")

    bundle.infoDictionary = [:]

    XCTAssertTrue(
      InternalUtility.shared.isRegisteredCanOpenURLScheme(name),
      "Should return the cached value of the main bundle and not the updated values"
    )
  }

  func testFacebookAppInstalledMissingQuerySchemes() {
    bundle = TestBundle(infoDictionary: [:])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isFacebookAppInstalled)

    verifyTestLoggerInvoked(loggingBehavior: .developerErrors, logEntry: facebookUrlSchemeMissingMessage)
  }

  func testFacebookAppInstalledEmptyQuerySchemes() {
    let querySchemes = [String]()
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isFacebookAppInstalled)

    verifyTestLoggerInvoked(loggingBehavior: .developerErrors, logEntry: facebookUrlSchemeMissingMessage)
  }

  func testFacebookAppInstalledMissingQueryScheme() {
    let querySchemes = ["Foo"]
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isFacebookAppInstalled)

    verifyTestLoggerInvoked(loggingBehavior: .developerErrors, logEntry: facebookUrlSchemeMissingMessage)
  }

  func testFacebookAppInstalledValidQueryScheme() {
    let querySchemes = ["fbauth2"]
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isFacebookAppInstalled)

    XCTAssertNil(TestLogger.capturedLoggingBehavior)
  }

  func testFacebookAppInstalledCache() {
    bundle = TestBundle(infoDictionary: [:])
    configureInternalUtility()

    XCTAssertEqual(logger.logEntryCallCount, 0, "There should not be developer errors logged initially")

    XCTAssertFalse(InternalUtility.shared.isFacebookAppInstalled)

    XCTAssertEqual(logger.logEntryCallCount, 1, "One developer error should be logged")
    verifyTestLoggerInvoked(loggingBehavior: .developerErrors, logEntry: facebookUrlSchemeMissingMessage)

    // Calling it again should not result in an additional call to the singleShotLogEntry method
    XCTAssertFalse(InternalUtility.shared.isFacebookAppInstalled)
    XCTAssertEqual(logger.logEntryCallCount, 1, "Additional errors should not be logged for the same error")
  }

  func testMessengerAppInstalledMissingQuerySchemes() {
    bundle = TestBundle(infoDictionary: [:])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isMessengerAppInstalled)

    verifyTestLoggerInvoked(
      loggingBehavior: .developerErrors,
      logEntry: messengerUrlSchemeMissingMessage
    )
  }

  func testMessengerAppInstalledEmptyQuerySchemes() {
    let querySchemes = [String]()
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isMessengerAppInstalled)

    verifyTestLoggerInvoked(
      loggingBehavior: .developerErrors,
      logEntry: messengerUrlSchemeMissingMessage
    )
  }

  func testMessengerAppInstalledMissingQueryScheme() {
    let querySchemes = ["Foo"]
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isMessengerAppInstalled)

    verifyTestLoggerInvoked(
      loggingBehavior: .developerErrors,
      logEntry: messengerUrlSchemeMissingMessage
    )
  }

  func testMessengerAppInstalledValidQueryScheme() {
    let querySchemes = ["fb-messenger-share-api"]
    bundle = TestBundle(infoDictionary: ["LSApplicationQueriesSchemes": querySchemes])
    configureInternalUtility()

    XCTAssertFalse(InternalUtility.shared.isMessengerAppInstalled)

    XCTAssertNil(TestLogger.capturedLoggingBehavior)
  }

  func testMessengerAppInstalledCache() {
    bundle = TestBundle(infoDictionary: [:])
    configureInternalUtility()

    XCTAssertTrue(
      TestLogger.capturedLogEntries.isEmpty, "There should not be developer errors logged initially"
    )

    XCTAssertFalse(InternalUtility.shared.isMessengerAppInstalled)

    XCTAssertEqual(logger.logEntryCallCount, 1, "One developer error should be logged")
    verifyTestLoggerInvoked(
      loggingBehavior: .developerErrors,
      logEntry: messengerUrlSchemeMissingMessage
    )

    // Calling it again should not result in an additional call to the singleShotLogEntry method
    XCTAssertFalse(InternalUtility.shared.isMessengerAppInstalled)
    XCTAssertEqual(logger.logEntryCallCount, 1, "Additional errors should not be logged for the same error")
  }

  // MARK: - Random Utility Methods

  func testIsBrowserURLWithNonBrowserURL() {
    [
      URL(string: "file://foo")!, // swiftlint:disable:this force_unwrapping
      URL(string: "example://bar")! // swiftlint:disable:this force_unwrapping
    ]
      .forEach { url in
        XCTAssertFalse(
          InternalUtility.shared.isBrowserURL(url),
          "\(url.absoluteString) should not be considered a browser url"
        )
      }
  }

  func testIsBrowserURLWithBrowserURL() {
    [
      URL(string: "HTTPS://example.com"),
      URL(string: "HTTP://example.com"),
      URL(string: "https://example.com"),
      URL(string: "http://example.com")
    ]
      .compactMap { $0 }
      .forEach { url in

        XCTAssertTrue(
          InternalUtility.shared.isBrowserURL(url),
          "\(url.absoluteString) should be considered a browser url"
        )
      }
  }

  func testIsFacebookBundleIdentifierWithInvalidIdentifiers() {
    [
      "",
      "foo",
      "com.foo.bar",
      "com.facebook"
    ]
      .forEach { identifier in
        XCTAssertFalse(
          InternalUtility.shared.isFacebookBundleIdentifier(identifier),
          "\(identifier) should not be considered a facebook bundle indentifier"
        )
      }
  }

  func testIsFacebookBundleIdentifierWithValidIdentifiers() {
    [
      "com.facebook.",
      "com.facebook.foo",
      ".com.facebook.",
      ".com.facebook.foo"
    ]
      .forEach { identifier in
        XCTAssertTrue(
          InternalUtility.shared.isFacebookBundleIdentifier(identifier),
          "\(identifier) should be considered a facebook bundle indentifier"
        )
      }
  }

  func testNonSafariBundleIdentifiers() {
    [
      "",
      " ",
      "com.foo"
    ]
      .forEach { identifier in
        XCTAssertFalse(
          InternalUtility.shared.isSafariBundleIdentifier(identifier),
          "\(identifier) should not be considered a safari bundle identifier"
        )
      }
  }

  func testSafariBundleIdentifiers() {
    [
      "com.apple.mobilesafari",
      "com.apple.SafariViewService"
    ]
      .forEach { identifier in
        XCTAssertTrue(
          InternalUtility.shared.isSafariBundleIdentifier(identifier),
          "\(identifier) should be considered a safari bundle identifier"
        )
      }
  }

  func testValidatingAppIDWhenUninitialized() {
    InternalUtility.reset()
    settings.appID = "abc"

    assertRaisesException(message: "Should raise an exception") {
      InternalUtility.shared.validateAppID()
    }
  }

  func testValidatingAppID() {
    settings.appID = nil

    assertRaisesException(message: "Should raise an exception") {
      InternalUtility.shared.validateAppID()
    }
  }

  func testValidateClientAccessTokenWhenUninitialized() {
    InternalUtility.reset()
    settings.appID = "abc"
    settings.clientToken = "123"

    assertRaisesException(message: "Should raise an exception") {
      InternalUtility.shared.validateRequiredClientAccessToken()
    }
  }

  func testValidateClientAccessTokenWithoutClientTokenWithoutAppID() {
    settings.appID = nil
    settings.clientToken = nil

    assertRaisesException(message: "Should raise an exception") {
      InternalUtility.shared.validateRequiredClientAccessToken()
    }
  }

  func testValidateClientAccessTokenWithClientTokenWithoutAppID() {
    settings.appID = nil
    settings.clientToken = "client123"

    XCTAssertEqual(
      InternalUtility.shared.validateRequiredClientAccessToken(),
      "(null)|client123",
      "A valid client-access token should include the app identifier and the client token"
    )
  }

  func testValidateClientAccessTokenWithClientTokenWithAppID() {
    settings.appID = "appid"
    settings.clientToken = "client123"

    XCTAssertEqual(
      InternalUtility.shared.validateRequiredClientAccessToken(),
      "appid|client123",
      "A valid client-access token should include the app identifier and the client token"
    )
  }

  func testValidateClientAccessTokenWithoutClientTokenWithAppID() {
    settings.appID = "appid"
    settings.clientToken = nil

    assertRaisesException(message: "Should raise an exception") {
      InternalUtility.shared.validateRequiredClientAccessToken()
    }
  }

  func testIsRegisteredUrlSchemeWithRegisteredScheme() {
    bundle = makeBundle(registeredUrlSchemes: ["com.foo.bar"])
    configureInternalUtility()

    XCTAssertTrue(
      InternalUtility.shared.isRegisteredURLScheme("com.foo.bar"),
      "Schemes in the bundle should be considered registered"
    )
  }

  func testIsRegisteredUrlSchemeWithoutRegisteredScheme() {
    bundle = makeBundle(registeredUrlSchemes: ["com.foo.bar"])
    configureInternalUtility()

    XCTAssertFalse(
      InternalUtility.shared.isRegisteredURLScheme("com.facebook"),
      "Schemes absent from the bundle should not be considered registered"
    )
  }

  func testIsRegisteredUrlSchemeCaching() {
    bundle = TestBundle()
    configureInternalUtility()

    InternalUtility.shared.isRegisteredURLScheme("com.facebook")

    XCTAssertTrue(
      bundle.didAccessInfoDictionary,
      "Should query the bundle for URL types"
    )
    bundle.reset()

    InternalUtility.shared.isRegisteredURLScheme("com.facebook")

    XCTAssertFalse(
      bundle.didAccessInfoDictionary,
      "Should not query the bundle more than once"
    )
  }

  func testValidatingUrlSchemesWithoutAppID() {
    settings.appID = nil

    assertRaisesException(
      message: "Cannot validate url schemes without an app identifier"
    ) {
      InternalUtility.shared.validateURLSchemes()
    }
  }

  func testValidatingUrlSchemesWhenNotConfigured() {
    assertRaisesException(
      message: "Cannot validate url schemes before configuring"
    ) {
      InternalUtility.shared.validateURLSchemes()
    }
  }

  func testValidatingUrlSchemesWithAppIdMatchingBundleEntry() {
    settings.appID = "appid"
    settings.appURLSchemeSuffix = nil
    bundle = makeBundle(registeredUrlSchemes: ["fbappid"])
    configureInternalUtility()

    assertDoesNotRaiseException(
      message: "The registered app url scheme must match the app id and url scheme suffix prepended with 'fb'"
    ) {
      InternalUtility.shared.validateURLSchemes()
    }
  }

  func testValidatingUrlSchemesWithNonAppIdMatchingBundleEntry() {
    settings.appID = "appid"
    settings.appURLSchemeSuffix = nil
    bundle = makeBundle(registeredUrlSchemes: ["fb123"])
    configureInternalUtility()

    assertRaisesException(
      message: "The registered app url scheme must match the app id and url scheme suffix prepended with 'fb'"
    ) {
      InternalUtility.shared.validateURLSchemes()
    }
  }

  // We can't loop through these because of how stubbing works.
  func testValidatingFacebookUrlSchemes_api() {
    bundle = makeBundle(registeredUrlSchemes: ["fbapi"])
    configureInternalUtility()

    assertRaisesException(
      message: "Should throw an error if fbapi is present in the bundle url schemes"
    ) {
      InternalUtility.shared.validateFacebookReservedURLSchemes()
    }
  }

  // We can't loop through these because of how stubbing works.
  func testValidatingFacebookUrlSchemes_messenger() {
    bundle = makeBundle(registeredUrlSchemes: ["fb-messenger-share-api"])
    configureInternalUtility()

    assertRaisesException(
      message: "Should throw an error if fb-messenger-share-api is present in the bundle url schemes"
    ) {
      InternalUtility.shared.validateFacebookReservedURLSchemes()
    }
  }

  func testExtendDictionaryWithDefaultDataProcessingOptions() {
    let parameters = NSMutableDictionary()
    InternalUtility.shared.extendDictionary(withDataProcessingOptions: parameters)

    XCTAssertEqual(
      parameters,
      [:],
      "Parameters should not change with default data processing options"
    )
  }

  func testExtendDictionaryWithDataProcessingOptions() {
    settings.persistableDataProcessingOptions = [
      "data_processing_options": ["LDU"],
      "data_processing_options_country": 10,
      "data_processing_options_state": 100
    ]

    let parameters = NSMutableDictionary()
    InternalUtility.shared.extendDictionary(withDataProcessingOptions: parameters)

    XCTAssertEqual(
      parameters["data_processing_options"] as? String,
      "[\"LDU\"]",
      "Parameters should be extended with expected data processing options"
    )
    XCTAssertEqual(
      parameters["data_processing_options_country"] as? Int,
      10,
      "Parameters should be extended with expected data processing options"
    )
    XCTAssertEqual(
      parameters["data_processing_options_state"] as? Int,
      100,
      "Parameters should be extended with expected data processing options"
    )
  }

  func testIsPublishPermission() {
    [
      "publish",
      "publishSomething",
      "manage",
      "manageSomething",
      "ads_management",
      "create_event",
      "rsvp_event"
    ]
      .forEach { permission in
        XCTAssertTrue(InternalUtility.shared.isPublishPermission(permission))
      }

    [
      "",
      "email",
      "_publish"
    ]
      .forEach { permission in
        XCTAssertFalse(InternalUtility.shared.isPublishPermission(permission))
      }
  }

  func testIsUnityWithMissingSuffix() {
    settings.userAgentSuffix = nil
    XCTAssertFalse(
      InternalUtility.shared.isUnity,
      "User agent should determine whether an app is Unity"
    )
  }

  func testIsUnityWithNonUnitySuffix() {
    settings.userAgentSuffix = "Foo"
    XCTAssertFalse(
      InternalUtility.shared.isUnity,
      "User agent should determine whether an app is Unity"
    )
  }

  func testIsUnityWithUnitySuffix() {
    settings.userAgentSuffix = "__Unity__"
    XCTAssertTrue(
      InternalUtility.shared.isUnity,
      "User agent should determine whether an app is Unity"
    )
  }

  func testHexadecimalStringFromData() throws {
    XCTAssertNil(
      InternalUtility.shared.hexadecimalString(from: Data())
    )

    let data = try XCTUnwrap("foo".data(using: .utf8))
    let expected = "666f6f"

    XCTAssertEqual(
      InternalUtility.shared.hexadecimalString(from: data),
      expected
    )
  }

  func testObjectIsEqualToObject() {
    var obj1: Any? = "foo"
    let obj2: Any = "foo"
    let obj3: Any = "bar"

    XCTAssertTrue(InternalUtility.shared.object(obj1 as Any, isEqualTo: obj1 as Any))
    XCTAssertTrue(InternalUtility.shared.object(obj1 as Any, isEqualTo: obj2))
    XCTAssertFalse(InternalUtility.shared.object(obj1 as Any, isEqualTo: obj3))

    obj1 = nil
    XCTAssertFalse(InternalUtility.shared.object(obj1 as Any, isEqualTo: obj2))
    XCTAssertFalse(InternalUtility.shared.object(obj2, isEqualTo: obj1 as Any))
  }

  // MARK: - Helpers

  func verifyTestLoggerInvoked(
    loggingBehavior: LoggingBehavior,
    logEntry: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    XCTAssertEqual(
      loggerFactory.capturedLoggingBehavior,
      loggingBehavior,
      file: file,
      line: line
    )
    XCTAssertEqual(
      logger.capturedContents,
      logEntry,
      file: file,
      line: line
    )
  }

  func makeCookie(url: URL, name: String = "MyCookie") -> HTTPCookie {
    HTTPCookie(
      properties: [
        .originURL: url,
        .path: url.path,
        .name: name,
        .value: "Is good"
      ]
    )! // swiftlint:disable:this force_unwrapping
  }

  func makeBundle(registeredUrlSchemes: [String]) -> TestBundle {
    TestBundle(
      infoDictionary: [
        "CFBundleURLTypes": [
          ["CFBundleURLSchemes": registeredUrlSchemes]
        ]
      ]
    )
  }
}
