/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import UIKit
import XCTest

/// `_ScreenTitleObserver` gating. The swizzle is process-permanent, so these cover capture and read, not install.
final class ScreenTitleObserverMetaDataTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var settings: TestSettings!
  var featureChecker: TestFeatureManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    settings = TestSettings()
    settings.isMetaDataCollectionEnabled = true
    // The real feature manager is unconfigured in this target and reports every feature
    // disabled, which would suppress every capture below and let these tests pass vacuously.
    featureChecker = TestFeatureManager()
    featureChecker.enable(feature: .metadataCollection)
    _ScreenTitleObserver.shared.settings = settings
    _ScreenTitleObserver.shared.featureChecker = featureChecker
  }

  override func tearDown() {
    _ScreenTitleObserver.shared.setScreenTitle(nil)
    _ScreenTitleObserver.shared.settings = Settings.shared
    _ScreenTitleObserver.shared.featureChecker = _FeatureManager.shared
    settings = nil
    featureChecker = nil

    super.tearDown()
  }

  /// `TestFeatureManager.disableFeature` only records for crash-shield assertions; `isEnabled`
  /// reads a separate stub map. Swapping in a fresh instance is what actually reports the
  /// GateKeeper as off.
  private func turnOffMetadataCollectionGateKeeper() {
    featureChecker = TestFeatureManager()
    _ScreenTitleObserver.shared.featureChecker = featureChecker
  }

  // MARK: - Server kill switch

  func testCapturingScreenTitleIsSuppressedWhenMetadataCollectionFeatureIsDisabled() {
    turnOffMetadataCollectionGateKeeper()

    _ScreenTitleObserver.shared.setScreenTitle("Checkout")

    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "Should not capture a screen title while the MetadataCollection GateKeeper is off"
    )
  }

  // Unlike the app link URLs, the GateKeeper gates capture here as well as read: a title taken
  // before the GateKeeper loaded carries no attribution value, so there is nothing to preserve.
  func testTitleCapturedBeforeTheGateKeeperClosedIsNotSurfacedAfterwards() {
    _ScreenTitleObserver.shared.setScreenTitle("Checkout")

    turnOffMetadataCollectionGateKeeper()

    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "Should not surface a screen title captured before the GateKeeper was turned off"
    )
  }

  func testCapturingRequiresBothTheClientFlagAndTheGateKeeper() {
    settings.isMetaDataCollectionEnabled = false
    featureChecker.enable(feature: .metadataCollection)
    _ScreenTitleObserver.shared.setScreenTitle("flag-off")
    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "The GateKeeper being on should not override the developer's opt-out"
    )

    settings.isMetaDataCollectionEnabled = true
    turnOffMetadataCollectionGateKeeper()
    _ScreenTitleObserver.shared.setScreenTitle("gk-off")
    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "The developer opting in should not override the GateKeeper"
    )
  }

  func testCapturingScreenTitleIsSuppressedWhenCollectionIsDisabled() {
    settings.isMetaDataCollectionEnabled = false

    _ScreenTitleObserver.shared.setScreenTitle("Checkout")

    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "Should not capture a screen title when the developer has opted out of metadata collection"
    )
  }

  func testReadingScreenTitleIsSuppressedWhenCollectionIsDisabled() {
    _ScreenTitleObserver.shared.setScreenTitle("Checkout")

    settings.isMetaDataCollectionEnabled = false

    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "Should not surface a screen title captured before the developer opted out"
    )
  }

  // The swizzle keeps firing after opt-out, so the next transition must erase, not freeze.
  func testViewDidAppearErasesStaleTitleWhenCollectionIsDisabled() {
    _ScreenTitleObserver.shared.startObserving()

    let firstScreen = UIViewController()
    firstScreen.title = "Checkout"
    firstScreen.viewDidAppear(true)
    XCTAssertEqual(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "Checkout",
      "sanity check: the title should be captured while collection is enabled"
    )

    settings.isMetaDataCollectionEnabled = false

    let secondScreen = UIViewController()
    secondScreen.title = "Receipt"
    secondScreen.viewDidAppear(true)

    // Re-enabled before asserting, so a nil result proves erasure rather than read gating.
    settings.isMetaDataCollectionEnabled = true

    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "A screen transition while opted out should clear the previously captured title"
    )
  }

  // The opt-out must never break the host app: its own viewDidAppear: has to complete either way.
  func testViewDidAppearCompletesForTheHostAppWhenCollectionIsDisabled() {
    _ScreenTitleObserver.shared.startObserving()
    _ScreenTitleObserver.shared.setScreenTitle("Checkout")
    settings.isMetaDataCollectionEnabled = false

    let viewController = ViewDidAppearRecordingViewController()
    viewController.viewDidAppear(true)

    // The cleared title is the observable proof that the swizzled implementation ran and took the
    // disabled branch; the call count alone would pass even with the swizzle uninstalled, since
    // the subclass override increments it directly.
    settings.isMetaDataCollectionEnabled = true
    XCTAssertNil(
      _ScreenTitleObserver.shared.currentScreenTitle(),
      "The swizzled viewDidAppear: should have run and cleared the title while collection was disabled"
    )
    XCTAssertEqual(
      viewController.viewDidAppearCallCount,
      1,
      "The view controller's own viewDidAppear: should still run to completion when collection is disabled"
    )
  }
}

private final class ViewDidAppearRecordingViewController: UIViewController {
  var viewDidAppearCallCount = 0

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewDidAppearCallCount += 1
  }
}
