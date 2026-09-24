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

/// `_AppLinkURLCache` gating. Separate from the ObjC tests because `TestSettings` is Swift-only.
final class AppLinkURLCacheMetaDataTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var dataStore: UserDefaults!
  var settings: TestSettings!
  // swiftlint:enable implicitly_unwrapped_optional

  private static let suiteName = "AppLinkURLCacheMetaDataTests"
  private static let inboundKey = "com.facebook.sdk:inbound_url"
  private static let outboundKey = "com.facebook.sdk:outbound_url"

  override func setUp() {
    super.setUp()

    // An isolated suite keeps the tests from touching the app's standard defaults.
    dataStore = UserDefaults(suiteName: Self.suiteName)! // swiftlint:disable:this force_unwrapping
    settings = TestSettings()
    settings.isMetaDataCollectionEnabled = true
    _AppLinkURLCache.shared.dataStore = dataStore
    _AppLinkURLCache.shared.settings = settings
  }

  override func tearDown() {
    // `reset` restores the shared store and settings so a stubbed opt-out can't leak.
    _AppLinkURLCache.shared.reset()
    dataStore.removePersistentDomain(forName: Self.suiteName)
    dataStore = nil
    settings = nil

    super.tearDown()
  }

  func testCachingInboundURLIsSuppressedWhenCollectionIsDisabled() {
    settings.isMetaDataCollectionEnabled = false

    _AppLinkURLCache.shared.cacheInboundURL(URL(string: "myapp://in"))

    XCTAssertNil(
      dataStore.string(forKey: Self.inboundKey),
      "Should not persist an inbound URL when the developer has opted out of metadata collection"
    )
  }

  func testCachingOutboundURLIsSuppressedWhenCollectionIsDisabled() {
    settings.isMetaDataCollectionEnabled = false

    _AppLinkURLCache.shared.cacheOutboundURL(URL(string: "https://example.com/out"))

    XCTAssertNil(
      dataStore.string(forKey: Self.outboundKey),
      "Should not persist an outbound URL when the developer has opted out of metadata collection"
    )
  }

  func testReadingURLsIsSuppressedWhenCollectionIsDisabled() {
    _AppLinkURLCache.shared.cacheInboundURL(URL(string: "myapp://in"))
    _AppLinkURLCache.shared.cacheOutboundURL(URL(string: "https://example.com/out"))

    settings.isMetaDataCollectionEnabled = false

    XCTAssertNil(
      _AppLinkURLCache.shared.inboundURL,
      "Should not surface an inbound URL cached before the developer opted out"
    )
    XCTAssertNil(
      _AppLinkURLCache.shared.outboundURL,
      "Should not surface an outbound URL cached before the developer opted out"
    )
  }

  // Read gating conceals; it does not erase. That's why the Settings setter clears the cache.
  func testDisablingCollectionAloneDoesNotEraseAlreadyCachedURLs() {
    _AppLinkURLCache.shared.cacheInboundURL(URL(string: "myapp://in"))

    settings.isMetaDataCollectionEnabled = false

    XCTAssertEqual(
      dataStore.string(forKey: Self.inboundKey),
      "myapp://in",
      "Gating the read should hide the persisted URL without removing it from disk"
    )
  }

  func testReEnablingCollectionSurfacesPreviouslyCachedURLs() {
    _AppLinkURLCache.shared.cacheInboundURL(URL(string: "myapp://in"))
    settings.isMetaDataCollectionEnabled = false
    settings.isMetaDataCollectionEnabled = true

    XCTAssertEqual(
      _AppLinkURLCache.shared.inboundURL,
      "myapp://in",
      "Should surface the cached URL again once collection is re-enabled"
    )
  }

  func testClearCachedURLsRemovesBothKeys() {
    _AppLinkURLCache.shared.cacheInboundURL(URL(string: "myapp://in"))
    _AppLinkURLCache.shared.cacheOutboundURL(URL(string: "https://example.com/out"))

    _AppLinkURLCache.shared.clearCachedURLs()

    XCTAssertNil(
      dataStore.string(forKey: Self.inboundKey),
      "Should remove the persisted inbound URL"
    )
    XCTAssertNil(
      dataStore.string(forKey: Self.outboundKey),
      "Should remove the persisted outbound URL"
    )
  }

  // `clearCachedURLs` is the opt-out action itself, so it has to work while opted out.
  func testClearCachedURLsWorksWhileCollectionIsDisabled() {
    _AppLinkURLCache.shared.cacheInboundURL(URL(string: "myapp://in"))
    settings.isMetaDataCollectionEnabled = false

    _AppLinkURLCache.shared.clearCachedURLs()

    XCTAssertNil(
      dataStore.string(forKey: Self.inboundKey),
      "Should remove the persisted inbound URL even when collection is disabled"
    )
  }
}
