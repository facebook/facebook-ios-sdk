/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class AppLinkURLFactory: NSObject, _AppLinkURLCreating {
  func createAppLinkURL(with url: URL) -> _AppLinkURLProtocol {
    AppLinkURL(url: url)
  }
}
