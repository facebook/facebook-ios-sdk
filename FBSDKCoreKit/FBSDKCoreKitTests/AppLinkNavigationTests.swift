/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools

final class AppLinkNavigationTests: XCTestCase {

  struct AppLinkUrlPayload: Codable {
    let userAgent: String
    let version: String
    let extras: [String: String]
    let targetUrl: URL?

    enum CodingKeys: String, CodingKey {
      case userAgent = "user_agent"
      case version
      case extras
      case targetUrl = "target_url"
    }
  }

  var error: NSError?

  let target = AppLinkTarget(url: SampleURLs.valid, appStoreId: "123", appName: "ExampleApp")
  let emptyAppLink = AppLink(sourceURL: nil, targets: [], webURL: nil)
  let eventPoster = TestMeasurementEvent()
  let resolver = TestAppLinkResolver()
  let settings = Settings.shared

  lazy var navigation = AppLinkNavigation(
    appLink: emptyAppLink,
    extras: [:],
    appLinkData: [:],
    settings: settings
  )

  override class func setUp() {
    super.setUp()

    AppLinkNavigation.reset()
  }

  override func setUp() {
    super.setUp()

    AppLinkNavigation.default = resolver
  }

  override class func tearDown() {
    super.tearDown()

    AppLinkNavigation.reset()
  }

  func testDefaultClassDependencies() {
    AppLinkNavigation.reset()

    XCTAssertNil(
      AppLinkNavigation.settings,
      "Should not have a settings by default"
    )
    XCTAssertNil(
      AppLinkNavigation.urlOpener,
      "Should not have a url opener by default"
    )
    XCTAssertNil(
      AppLinkNavigation.appLinkEventPoster,
      "Should not have an event poster by default"
    )
    XCTAssertNil(
      AppLinkNavigation.appLinkResolver,
      "Should not have an app link resolver by default"
    )
  }

  func testDefaultResolver() {
    AppLinkNavigation.reset()
    XCTAssertTrue(
      AppLinkNavigation.default === WebViewAppLinkResolver.shared,
      "Should use the shared webview app link resolver by default"
    )
  }

  func testSettingDefaultResolver() {
    let resolver = AppLinkResolver()
    AppLinkNavigation.default = resolver

    XCTAssertTrue(
      AppLinkNavigation.default === resolver,
      "Should be able to set the default app link resolver"
    )
    XCTAssertTrue(
      AppLinkNavigation.appLinkResolver === resolver,
      "Should set the underlying resolver when setting the default"
    )
  }

  func testCreatingWithEmptyAppLink() {
    XCTAssertNotNil(
      navigation,
      "Should be able to create an app link without verifying anything about it at all"
    )
  }

  func testCallbackAppLinkData() {
    XCTAssertEqual(
      AppLinkNavigation.callbackAppLinkData(forApp: "foo", url: "bar"),
      ["referer_app_link": ["app_name": "foo", "url": "bar"]],
      "Should produce the expected app link callback data"
    )
  }

  // MARK: - Dependencies Configuration

  func testDependenciesArePassed() {
    XCTAssertNotNil(
      navigation.settings,
      "Settings dependency should not be nil"
    )
  }

  // MARK: - Link Creation

  func testAppLinkWithTargetUrl() {
    do {
      let url = try navigation.appLinkURL(withTargetURL: SampleURLs.valid)
      let payload = decodedPayload(url: url)

      XCTAssertEqual(payload?.userAgent, "FBSDK \(FBSDK_VERSION_STRING)")
      XCTAssertEqual(payload?.version, "1.0")
      XCTAssertEqual(payload?.extras, [:])
      XCTAssertNil(payload?.targetUrl)
    } catch {
      XCTAssertNil(
        error,
        "Should not populate an error when creating an app link with a valid target url"
      )
    }
  }

  func testAppLinkWithTargetUrlWithValidStartingAppLink() {
    let appLink = AppLink(sourceURL: SampleURLs.valid, targets: [target], webURL: SampleURLs.valid)
    navigation = AppLinkNavigation(
      appLink: appLink, extras: [:], appLinkData: [:], settings: settings
    )
    do {
      let url = try navigation.appLinkURL(withTargetURL: SampleURLs.valid)
      let payload = decodedPayload(url: url)

      XCTAssertEqual(payload?.userAgent, "FBSDK \(FBSDK_VERSION_STRING)")
      XCTAssertEqual(payload?.version, "1.0")
      XCTAssertEqual(payload?.extras, [:])
      XCTAssertEqual(payload?.targetUrl, SampleURLs.valid)
    } catch {
      XCTAssertNil(
        error,
        "Should not populate an error when creating an app link with a valid target url"
      )
    }
  }

  func testAppLinkWithTargetUrlWithInvalidStartingAppLinkData() {
    navigation = AppLinkNavigation(
      appLink: emptyAppLink, extras: [:], appLinkData: ["foo": Any.self], settings: settings
    )

    do {
      let url = try navigation.appLinkURL(withTargetURL: SampleURLs.valid)

      guard
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
        let appLinkItem = queryItems.first(where: { $0.name == "al_applink_data" })
      else {
        return XCTFail("Should have a query item for app link data")
      }

      XCTAssertEqual(
        appLinkItem.value,
        "",
        "This probably shouldn't be the behavior but right now it is."
      )
    } catch {
      XCTAssertNil(
        error,
        "This probably shouldn't be the behavior but right now it is."
      )
    }
  }

  func testAppLinkWithTargetUrlWithValidStartingAppLinkData() {
    let appLinkData = ["user_agent": "foo", "version": "bar"]
    navigation = AppLinkNavigation(
      appLink: emptyAppLink, extras: ["some": "extra"], appLinkData: appLinkData, settings: settings
    )

    do {
      let url = try navigation.appLinkURL(withTargetURL: SampleURLs.valid)
      let payload = decodedPayload(url: url)

      XCTAssertEqual(payload?.userAgent, "foo")
      XCTAssertEqual(payload?.version, "bar")
      XCTAssertEqual(payload?.extras, ["some": "extra"])
      XCTAssertNil(payload?.targetUrl)
    } catch {
      XCTAssertNil(
        error,
        "Should not populate an error when creating an app link with a valid target url"
      )
    }
  }

  func testAppLinkWithBadData() {
    let unencodable = String(
      bytes: [0xD8, 0x00] as [UInt8],
      encoding: String.Encoding.utf16BigEndian
    )! // swiftlint:disable:this force_unwrapping
    let appLinkData = ["bad value": unencodable]
    navigation = AppLinkNavigation(appLink: emptyAppLink, extras: [:], appLinkData: appLinkData, settings: settings)

    do {
      let url = try navigation.appLinkURL(withTargetURL: SampleURLs.valid)
      let payload = decodedPayload(url: url)
      XCTAssertEqual(payload?.userAgent, "foo")
      XCTAssertEqual(payload?.version, "bar")
      XCTAssertEqual(payload?.extras, ["some": "extra"])
      XCTAssertNil(payload?.targetUrl)
      XCTAssertNil(
        error,
        "Should not populate an error when creating an app link with a valid target url"
      )
    } catch {
      print(error)
    }
  }

  // MARK: - Posting Navigation Events

  func testPostingNavigationEventWithTypeApp() {
    navigation.postAppLinkNavigateEventNotification(
      withTargetURL: nil,
      error: nil,
      type: .app,
      eventPoster: eventPoster
    )
    XCTAssertEqual(
      eventPoster.capturedEventName,
      AppLinkNavigateOutEventName,
      "Should post a notification with the expected event name"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs,
      ["type": "app", "success": "1"],
      "Post an event with type 'app' should be considered a success"
    )
  }

  func testPostingNavigationEventWithTypeBrowser() {
    navigation.postAppLinkNavigateEventNotification(
      withTargetURL: nil,
      error: nil,
      type: .browser,
      eventPoster: eventPoster
    )
    XCTAssertEqual(
      eventPoster.capturedEventName,
      AppLinkNavigateOutEventName,
      "Should post a notification with the expected event name"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs,
      ["type": "web", "success": "1"],
      "Post an event with type 'browser' should be considered a success"
    )
  }

  func testPostingNavigationEventWithTypeFailure() {
    navigation.postAppLinkNavigateEventNotification(
      withTargetURL: nil,
      error: nil,
      type: .failure,
      eventPoster: eventPoster
    )
    XCTAssertEqual(
      eventPoster.capturedEventName,
      AppLinkNavigateOutEventName,
      "Should post a notification with the expected event name"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs,
      ["type": "fail", "success": "0"],
      "Post an event with type 'failure' should be considered a failure"
    )
  }

  func testPostingNavigationEventWithAppLink() {
    let appLink = AppLink(sourceURL: SampleURLs.valid, targets: [target], webURL: SampleURLs.valid)
    navigation = AppLinkNavigation(
      appLink: appLink, extras: [:], appLinkData: [:], settings: settings
    )

    navigation.postAppLinkNavigateEventNotification(
      withTargetURL: nil,
      error: nil,
      type: .app,
      eventPoster: eventPoster
    )
    XCTAssertEqual(
      eventPoster.capturedEventName,
      AppLinkNavigateOutEventName,
      "Should post a notification with the expected event name"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs["sourceHost"],
      SampleURLs.valid.host,
      "A navigation event notification should include information about the app link"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs["sourceScheme"],
      SampleURLs.valid.scheme,
      "A navigation event notification should include information about the app link"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs["sourceURL"],
      SampleURLs.valid.absoluteString,
      "A navigation event notification should include information about the app link"
    )
  }

  func testPostingNavigationEventWithError() {
    navigation.postAppLinkNavigateEventNotification(
      withTargetURL: nil,
      error: SampleError(),
      type: .app,
      eventPoster: eventPoster
    )
    XCTAssertEqual(
      eventPoster.capturedEventName,
      AppLinkNavigateOutEventName,
      "Should post a notification with the expected event name"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs["error"],
      "The operation couldn’t be completed. (TestTools.SampleError error 1.)",
      "A navigation event notification should include information about any errors"
    )
    XCTAssertEqual(
      eventPoster.capturedArgs["success"],
      "1",
      "A navigation event notification should be considered successful even if there's an error"
    )
  }

  func testPostingNavigationEventWithBackToReferrer() {
    let appLink = AppLink(sourceURL: nil, targets: [], webURL: nil, isBackToReferrer: true)
    navigation = AppLinkNavigation(
      appLink: appLink, extras: [:], appLinkData: [:], settings: settings
    )

    navigation.postAppLinkNavigateEventNotification(
      withTargetURL: nil,
      error: nil,
      type: .app,
      eventPoster: eventPoster
    )

    XCTAssertEqual(
      eventPoster.capturedEventName,
      AppLinkNavigateBackToReferrerEventName,
      "A navigation event notification should be indicate if the app link points back to the referrer"
    )
  }

  // MARK: - Navigation Type

  func testNavigationTypeWithoutTarget() {
    XCTAssertEqual(
      navigation.navigationType(for: [], urlOpener: TestInternalURLOpener(canOpenURL: true)),
      .failure,
      "The navigation type for an empty list of targets should be a failure"
    )
  }

  func testNavigationTypeWithInvalidTargetWithoutWebUrl() {
    let target = AppLinkTarget(url: SampleURLs.valid, appStoreId: nil, appName: name)
    let appLink = AppLink(sourceURL: nil, targets: [target], webURL: nil)
    navigation = AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:], settings: settings)

    XCTAssertEqual(
      navigation.navigationType(for: [target], urlOpener: TestInternalURLOpener(canOpenURL: false)),
      .failure,
      "The navigation type when there is an invalid target and no web url should be 'failure'"
    )
  }

  func testNavigationTypeWithValidTargetWithoutWebUrl() {
    let target = AppLinkTarget(url: SampleURLs.valid, appStoreId: nil, appName: name)
    let appLink = AppLink(sourceURL: nil, targets: [target], webURL: nil)
    navigation = AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:], settings: settings)

    XCTAssertEqual(
      navigation.navigationType(for: [target], urlOpener: TestInternalURLOpener(canOpenURL: true)),
      .app,
      "The navigation type when there is a valid target and no web url should be 'app'"
    )
  }

  func testNavigationTypeWithValidTargetWithWebUrl() {
    let target = AppLinkTarget(url: SampleURLs.valid, appStoreId: nil, appName: name)
    let appLink = AppLink(sourceURL: nil, targets: [target], webURL: SampleURLs.valid)
    navigation = AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:], settings: settings)

    XCTAssertEqual(
      navigation.navigationType(for: [target], urlOpener: TestInternalURLOpener(canOpenURL: true)),
      .app,
      "The navigation type when there is a valid target and a web url should be 'app'"
    )
  }

  func testNavigationTypeWithInvalidTargetWithWebUrl() {
    let target = AppLinkTarget(url: SampleURLs.valid, appStoreId: nil, appName: name)
    let appLink = AppLink(sourceURL: nil, targets: [target], webURL: SampleURLs.valid)
    navigation = AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:], settings: settings)

    XCTAssertEqual(
      navigation.navigationType(for: [target], urlOpener: TestInternalURLOpener(canOpenURL: false)),
      .browser,
      "The navigation type when there is an invalid target and a web url should be 'browser'"
    )
  }

  // MARK: - Navigating

  func testSuccessfullyNavigatingWithTargetWithoutWebUrl() {
    let target = AppLinkTarget(url: SampleURLs.valid, appStoreId: nil, appName: name)
    let appLink = AppLink(sourceURL: nil, targets: [target], webURL: nil)
    let opener = TestInternalURLOpener(canOpenURL: true)
    navigation = AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:], settings: settings)

    do {
      let targetUrl = try navigation.appLinkURL(withTargetURL: SampleURLs.valid)

      opener.stubOpen(url: targetUrl, success: true)

      let result = navigation.navigate(
        urlOpener: opener,
        eventPoster: eventPoster,
        error: &error
      )
      XCTAssertEqual(result, .app, "Should return the correct navigation type")
      XCTAssertNotNil(
        opener.capturedOpenURL,
        "Should create an open a url for a valid target"
      )
      XCTAssertEqual(
        opener.capturedOpenURL?.absoluteString,
        eventPoster.capturedArgs["outputURL"],
        "Should post a notification with the url that was opened"
      )
    } catch {
      XCTAssertNil(error)
    }
  }

  func testUnsuccessfullyNavigatingWithTargetWithWebUrl() {
    let target = AppLinkTarget(url: SampleURLs.valid, appStoreId: nil, appName: name)
    let appLink = AppLink(sourceURL: nil, targets: [target], webURL: SampleURLs.valid(path: name))
    let opener = TestInternalURLOpener(canOpenURL: true)
    navigation = AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:], settings: settings)

    do {
      let targetUrl = try navigation.appLinkURL(withTargetURL: SampleURLs.valid)
      let webUrl = try navigation.appLinkURL(withTargetURL: SampleURLs.valid(path: name))

      opener.stubOpen(url: targetUrl, success: false)
      opener.stubOpen(url: webUrl, success: true)

      let result = navigation.navigate(
        urlOpener: opener,
        eventPoster: eventPoster,
        error: &error
      )
      XCTAssertEqual(result, .browser, "Should return the correct navigation type")
      XCTAssertNotNil(
        opener.capturedOpenURL,
        "Should create an open a url for a valid target"
      )
      XCTAssertEqual(
        opener.capturedOpenURL?.absoluteString,
        eventPoster.capturedArgs["outputURL"],
        "Should post a notification with the url that was opened"
      )
    } catch {
      XCTAssertNil(error)
    }
  }

  func testNavigatingToUrlWithoutAppLink() {
    let expectation = self.expectation(description: name)
    AppLinkNavigation.navigate(to: SampleURLs.valid) { _, _ in
      expectation.fulfill()
    }

    // The captured completion itself is dispatched asynchronously to the main thread
    // so we can delay a tick here to make sure it's complete
    DispatchQueue.main.async {
      self.resolver.capturedCompletion?(nil, nil)
    }

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testNavigatingToUrlWithAppLink() {
    let expectation = self.expectation(description: name)
    var callbackNavigationType: AppLinkNavigation.`Type`?
    var callbackError: Error?

    AppLinkNavigation.navigate(to: SampleURLs.valid) { potentialNavigationType, potentialError in
      callbackNavigationType = potentialNavigationType
      callbackError = potentialError
      expectation.fulfill()
    }

    let appLink = AppLink(sourceURL: SampleURLs.valid, targets: [], webURL: nil)

    // The captured completion itself is dispatched asynchronously to the main thread
    // so we can delay a tick here to make sure it's complete
    DispatchQueue.main.async {
      self.resolver.capturedCompletion?(appLink, nil)
    }
    waitForExpectations(timeout: 1, handler: nil)

    XCTAssertEqual(callbackNavigationType, .failure)
    XCTAssertNil(callbackError)
  }

  func testNavigatingToUrlWithError() {
    let expectation = self.expectation(description: name)
    var callbackNavigationType: AppLinkNavigation.`Type`?
    var callbackError: Error?

    AppLinkNavigation.navigate(to: SampleURLs.valid) { potentialNavigationType, potentialError in
      callbackNavigationType = potentialNavigationType
      callbackError = potentialError
      expectation.fulfill()
    }

    let appLink = AppLink(sourceURL: SampleURLs.valid, targets: [], webURL: nil)

    // The captured completion itself is dispatched asynchronously to the main thread
    // so we can delay a tick here to make sure it's complete
    DispatchQueue.main.async {
      self.resolver.capturedCompletion?(
        appLink,
        NSError(domain: "foo", code: 0, userInfo: nil)
      )
    }
    waitForExpectations(timeout: 1, handler: nil)

    XCTAssertEqual(callbackNavigationType, .failure)
    XCTAssertNotNil(callbackError)
  }

  // MARK: - Resolving

  func testResolvingAppLinkWithMissingDestination() {
    var didInvokeCompletion = false
    AppLinkNavigation.resolveAppLink(SampleURLs.valid) { _, _ in
      didInvokeCompletion = true
    }
    resolver.capturedCompletion?(nil, nil)

    XCTAssertEqual(
      resolver.capturedURL,
      SampleURLs.valid,
      "Should resolve using the provided url"
    )
    XCTAssertTrue(didInvokeCompletion)
  }

  // MARK: - Helpers

  func decodedPayload(
    url: URL,
    file: StaticString = #file,
    line: UInt = #line
  ) -> AppLinkUrlPayload? {
    guard
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let queryItems = components.queryItems,
      let data = queryItems.first?.value?.data(using: .utf8),
      let payload = try? JSONDecoder().decode(AppLinkUrlPayload.self, from: data)
    else {
      XCTFail("Could not decode the payload from the query item", file: file, line: line)
      return nil
    }

    return payload
  }
}
