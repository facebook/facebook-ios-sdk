/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

extension AppLinkNavigation {

  @available(iOS 13, *)
  @objc
  static var testURLOpener: TestInternalURLOpener? {
    // swiftformat:disable:next redundantSelf
    self.urlOpener as? TestInternalURLOpener
  }

  @available(iOS 13, *)
  @objc
  public static func setTestTypeDependencies() {
    AppLinkNavigation.setDependencies(
      .init(
        settings: TestSettings(),
        urlOpener: TestInternalURLOpener(),
        appLinkEventPoster: TestAppLinkEventPoster(),
        appLinkResolver: TestAppLinkResolver()
      )
    )
  }

  @available(iOS 13, *)
  @objc
  public static func resetTestTypeDependencies() {
    AppLinkNavigation.resetDependencies()
  }
}
