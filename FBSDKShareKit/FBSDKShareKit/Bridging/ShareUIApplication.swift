/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

enum ShareUIApplication {
  static let shared: ShareInternalURLOpening = {
    #if DEBUG
    TestShareInternalURLOpener()
    #else
    UIApplication.shared
    #endif
  }()
}

#if DEBUG
private final class TestShareInternalURLOpener: ShareInternalURLOpening {
  func canOpenURL(_ url: URL) -> Bool { false }
}
#endif
