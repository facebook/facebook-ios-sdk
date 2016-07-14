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

import UIKit

@testable import FacebookCore
import FBSDKLoginKit

/**
 A button that initiates a log in or log out flow upon tapping.

 `LoginButton` works with `AccessToken.current` to determine what to display,
 and automatically starts authentication when tapped (i.e., you do not need to manually subscribe action targets).

 Like `LoginManager`, you should make sure your app delegate is connected to `ApplicationDelegate`
 in order for the button's delegate to receive messages.

 `LoginButton` has a fixed height of @c 30 pixels, but you may change the width.
 Initializing the button with `nil` frame will size the button to its minimum frame.
 */
public class LoginButton: UIView {

  private var sdkLoginButton: FBSDKLoginButton

  /// Delegate of the login button that can handle the result, logout events.
  public var delegate: LoginButtonDelegate?
  private var delegateBridge: LoginButtonDelegateBridge

  /// The login behavior that is going to be used. Default: `.Native`.
  public var loginBehavior = LoginBehavior.Native {
    didSet {
      sdkLoginButton.loginBehavior = loginBehavior.sdkBehavior
    }
  }

  /// The default audience. Default: `.Friends`.
  public var defaultAudience = LoginDefaultAudience.Friends {
    didSet {
      sdkLoginButton.defaultAudience = defaultAudience.sdkAudience
    }
  }

  /// The desired tooltip behavior. Default: `.Automatic`.
  public var tooltipBehavior = TooltipBehavior.Automatic {
    didSet {
      sdkLoginButton.tooltipBehavior = tooltipBehavior.sdkBehavior
    }
  }

  /// The desired tooltip color style. Default: `.FriendlyBlue`.
  public var tooltipColorStyle = TooltipColorStyle.FriendlyBlue {
    didSet {
      sdkLoginButton.tooltipColorStyle = tooltipColorStyle.sdkColorStyle
    }
  }

  /**
   Create a new `LoginButton` with a given optional frame and read permissions.

   - parameter frame:              Optional frame to initialize with. Default: `nil`, which uses a default size for the button.
   - parameter readPermissions: Array of read permissions to request when logging in.
   */
  public init(frame: CGRect? = nil, readPermissions: [ReadPermission]) {
    let sdkLoginButton = FBSDKLoginButton()
    sdkLoginButton.readPermissions = readPermissions.map({ $0.permissionValue.name })

    self.sdkLoginButton = sdkLoginButton
    delegateBridge = LoginButtonDelegateBridge()

    let frame = frame ?? CGRect(origin: .zero, size: sdkLoginButton.bounds.size)
    super.init(frame: frame)

    delegateBridge.setupAsDelegateFor(sdkLoginButton, loginButton: self)
    addSubview(sdkLoginButton)
  }

  /**
   Create a new `LoginButton` with a given optional frame and publish permissions.

   - parameter frame:              Optional frame to initialize with. Default: `nil`, which uses a default size for the button.
   - parameter publishPermissions: Array of publish permissions to request when logging in.
   */
  public init(frame: CGRect? = nil, publishPermissions: [PublishPermission]) {
    let sdkLoginButton = FBSDKLoginButton()
    sdkLoginButton.publishPermissions = publishPermissions.map({ $0.permissionValue.name })

    self.sdkLoginButton = sdkLoginButton
    delegateBridge = LoginButtonDelegateBridge()

    let frame = frame ?? sdkLoginButton.bounds
    super.init(frame: frame)

    delegateBridge.setupAsDelegateFor(sdkLoginButton, loginButton: self)
    addSubview(sdkLoginButton)
  }

  /**
   Create a new `LoginButton` from an encoded interface file.

   - parameter decoder: The coder to initialize from.
   */
  public required init?(coder decoder: NSCoder) {
    sdkLoginButton = FBSDKLoginButton(coder: decoder) ?? FBSDKLoginButton()
    delegateBridge = LoginButtonDelegateBridge()

    super.init(coder: decoder)

    delegateBridge.setupAsDelegateFor(sdkLoginButton, loginButton: self)
    addSubview(sdkLoginButton)
  }
}

extension LoginButton {

  public override func layoutSubviews() {
    super.layoutSubviews()

    sdkLoginButton.frame = CGRect(origin: .zero, size: bounds.size)
  }

  public override func sizeToFit() {
    bounds.size = sizeThatFits(CGSize(width: CGFloat.max, height: CGFloat.max))
  }

  public override func sizeThatFits(size: CGSize) -> CGSize {
    return sdkLoginButton.sizeThatFits(size)
  }

  public override func intrinsicContentSize() -> CGSize {
    return sdkLoginButton.intrinsicContentSize()
  }
}
