// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if !TARGET_OS_TV

#if BUCK
import FacebookCore
#endif

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
