/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools

class AppLinkUtilityTests: XCTestCase {

  let graphRequestFactory = TestGraphRequestFactory()
  var bundle = TestBundle()
  let settings = TestSettings()
  let appEventsConfigurationProvider = TestAppEventsConfigurationProvider()
  let advertiserIDProvider = TestAdvertiserIDProvider()
  let appEventsDropDeterminer = TestAppEventsDropDeterminer()
  let appEventParametersExtractor = TestAppEventParametersExtractor()
  let userIDProvider = TestUserIDProvider()
  let userDataStore = TestUserDataStore()
  let appLinkURLFactory = TestAppLinkURLFactory()

  override func setUp() {
    super.setUp()

    appEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.valid
    configureUtility(infoDictionaryProvider: bundle)
  }

  override class func tearDown() {
    super.tearDown()

    AppLinkUtility.reset()
  }

  func testDefaultDependencies() {
    AppLinkUtility.reset()

    XCTAssertNil(
      AppLinkUtility.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      AppLinkUtility.infoDictionaryProvider,
      "Should not have an info dictionary provider by default"
    )
    XCTAssertNil(
      AppLinkUtility.settings,
      "Should not have settings by default"
    )
    XCTAssertNil(
      AppLinkUtility.appEventsConfigurationProvider,
      "Should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      AppLinkUtility.advertiserIDProvider,
      "Should not have an advertiser id provider by default"
    )
    XCTAssertNil(
      AppLinkUtility.appEventsDropDeterminer,
      "Should not have an app events drop determiner by default"
    )
    XCTAssertNil(
      AppLinkUtility.appEventParametersExtractor,
      "Should not have an app events parameters extractor by default"
    )
    XCTAssertNil(
      AppLinkUtility.appLinkURLFactory,
      "Should not have an app link URL factory by default"
    )
    XCTAssertNil(
      AppLinkUtility.userIDProvider,
      "Should not have a user ID provider by default"
    )
    XCTAssertNil(
      AppLinkUtility.userDataStore,
      "Should not have a user data store by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      AppLinkUtility.graphRequestFactory is TestGraphRequestFactory,
      "Should use the provided request provider type"
    )
    XCTAssertTrue(
      AppLinkUtility.infoDictionaryProvider is TestBundle,
      "Should use the provided info dictionary provider type"
    )
    XCTAssertTrue(
      AppLinkUtility.settings is TestSettings,
      "Should use the provided settings"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsConfigurationProvider is TestAppEventsConfigurationProvider,
      "Should use the provided app events configuration provider"
    )
    XCTAssertTrue(
      AppLinkUtility.advertiserIDProvider is TestAdvertiserIDProvider,
      "Should use the provided advertiser id provider"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsDropDeterminer is TestAppEventsDropDeterminer,
      "Should use the provided app events drop determiner"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventParametersExtractor is TestAppEventParametersExtractor,
      "Should use the provided app event parameters extractor"
    )
    XCTAssertTrue(
      AppLinkUtility.appLinkURLFactory is TestAppLinkURLFactory,
      "Should use the provided app link URL factory"
    )
    XCTAssertTrue(
      AppLinkUtility.userIDProvider is TestUserIDProvider,
      "Should use the provided user ID provider"
    )
    XCTAssertTrue(
      AppLinkUtility.userDataStore is TestUserDataStore,
      "Should use the provided user data store"
    )
  }

  func testWithNoPromoCode() {
    let url = URL(string: "myapp://somelink/?someparam=somevalue")! // swiftlint:disable:this force_unwrapping
    let promoCode = AppLinkUtility.appInvitePromotionCode(from: url)
    XCTAssertNil(promoCode)
  }

  func testWithPromoCode() throws {
    let deepLinkContext = try JSONSerialization.data(withJSONObject: ["promo_code": "PROMOWORKS"], options: [])
    let encodedDeepLinkContext = try XCTUnwrap(String(data: deepLinkContext, encoding: .utf8))
    appLinkURLFactory.stubbedAppLinkURL = TestAppLinkURL(
      appLinkExtras: ["deeplink_context": encodedDeepLinkContext]
    )
    let promoCode = AppLinkUtility.appInvitePromotionCode(from: SampleURLs.valid)
    XCTAssertEqual(promoCode, "PROMOWORKS")
  }

  func testIsMatchURLScheme() {
    let bundleDict = [
      "CFBundleURLTypes": [
        [
          "CFBundleURLSchemes": ["fb123"]
        ]
      ]
    ]
    bundle = TestBundle(infoDictionary: bundleDict)

    configureUtility(infoDictionaryProvider: bundle)

    XCTAssertTrue(AppLinkUtility.isMatchURLScheme("fb123"))
    XCTAssertFalse(AppLinkUtility.isMatchURLScheme("not_in_url_schemes"))
  }

  func testGraphRequestFactoryAfterGraphRequest() {
    AppLinkUtility.fetchDeferredAppLink()

    appEventsConfigurationProvider.firstCapturedBlock?()

    XCTAssertEqual(graphRequestFactory.capturedGraphPath, "(null)/activities")
    XCTAssertEqual(graphRequestFactory.capturedHttpMethod, HTTPMethod(rawValue: "POST"))
  }

  func testValidatingConfiguration() {
    AppLinkUtility.reset()
    assertRaisesException(message: "Should throw an exception if the utility has not been configured") {
      AppLinkUtility.validateConfiguration()
    }
  }

  // MARK: - Helpers

  func configureUtility(
    infoDictionaryProvider: InfoDictionaryProviding
  ) {
    AppLinkUtility.configure(
      graphRequestFactory: graphRequestFactory,
      infoDictionaryProvider: infoDictionaryProvider,
      settings: settings,
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      advertiserIDProvider: advertiserIDProvider,
      appEventsDropDeterminer: appEventsDropDeterminer,
      appEventParametersExtractor: appEventParametersExtractor,
      appLinkURLFactory: appLinkURLFactory,
      userIDProvider: userIDProvider,
      userDataStore: userDataStore
    )
  }
}
