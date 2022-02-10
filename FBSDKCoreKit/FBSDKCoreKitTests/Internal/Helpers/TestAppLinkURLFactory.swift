/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class TestAppLinkURLFactory: AppLinkURLCreating {
  var stubbedAppLinkURL: TestAppLinkURL?

  func createAppLinkURL(with url: URL) -> AppLinkURLProtocol {
    stubbedAppLinkURL ?? TestAppLinkURL()
  }
}
