/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc public final class CoreUIApplication: NSObject {
  public static let shared: _InternalURLOpener = {
    #if DEBUG
    TestUIApplication()
    #else
    UIApplication.shared
    #endif
  }()
}

#if DEBUG
private final class TestUIApplication: _InternalURLOpener {
  func canOpen(_ url: URL) -> Bool { false }

  func open(
    _ url: URL,
    options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:],
    completionHandler completion: ((Bool) -> Void)? = nil
  ) {}
}
#endif
