/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

import FBSDKCoreKit

import UIKit

/**
 A button that initiates a log in or log out flow upon tapping.

 `LoginButton` works with `AccessToken.current` to determine what to display,
 and automatically starts authentication when tapped (i.e., you do not need to manually subscribe action targets).

 Like `LoginManager`, you should make sure your app delegate is connected to `ApplicationDelegate`
 in order for the button's delegate to receive messages.

 `LoginButton` has a fixed height of @c 30 pixels, but you may change the width.
 Initializing the button with `nil` frame will size the button to its minimum frame.
 */
@available(tvOS, unavailable)
public extension FBLoginButton {
  /**
   Create a new `LoginButton` with a given optional frame and read permissions.

   - Parameter frame: Optional frame to initialize with. Default: `nil`, which uses a default size for the button.
   - Parameter permissions: Array of read permissions to request when logging in.
   */
  convenience init(frame: CGRect = .zero, permissions: [Permission] = [.publicProfile]) {
    self.init(frame: frame)
    self.permissions = permissions.map { $0.name }
  }
}

#endif
