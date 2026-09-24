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

  // swiftlint:disable:next implicitly_unwrapped_optional
  var settings: TestSettings!

  override func setUp() {
    super.setUp()

    settings = TestSettings()
    settings.isMetaDataCollectionEnabled = true
    _ScreenTitleObserver.shared.settings = settings
  }

  override func tearDown() {
    _ScreenTitleObserver.shared.setScreenTitle(nil)
    _ScreenTitleObserver.shared.settings = Settings.shared
    settings = nil

    super.tearDown()
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
