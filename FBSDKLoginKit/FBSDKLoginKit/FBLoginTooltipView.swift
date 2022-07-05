/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import UIKit

/**
 Represents a tooltip to be displayed next to a Facebook login button
 to highlight features for new users.

 The `FBSDKLoginButton` may display this view automatically. If you do
 not use the `FBSDKLoginButton`, you can manually call one of the `present*` methods
 as appropriate and customize behavior via `FBSDKLoginTooltipViewDelegate` delegate.

 By default, the `FBSDKLoginTooltipView` is not added to the superview until it is
 determined the app has migrated to the new login experience. You can override this
 (e.g., to test the UI layout) by implementing the delegate or setting `forceDisplay` to YES.
 */
@objc(FBSDKLoginTooltipView)
public final class FBLoginTooltipView: FBTooltipView {
  /// the delegate
  @objc public weak var delegate: LoginTooltipViewDelegate?

  /**
   if set to YES, the view will always be displayed and the delegate's
   `loginTooltipView:shouldAppear:` will NOT be called.
   */
  @objc public var forceDisplay: Bool = false

  /**
   if set to YES, the view will always be displayed and the delegate's
   `loginTooltipView:shouldAppear:` will NOT be called.
   */
  @objc public var shouldForceDisplay: Bool {
    get {
      forceDisplay
    }
    set {
      forceDisplay = newValue
    }
  }

  /// Service configuration provider
  let serverConfigurationProvider: ServerConfigurationProviding

  /// UI String provider
  let stringProvider: UserInterfaceStringProviding

  // MARK: - Init

  /// Create tooltip
  @objc public convenience init() {
    self.init(
      serverConfigurationProvider: ServerConfigurationProvider(),
      stringProvider: InternalUtility.shared
    )
  }

  @objc(initWithTagline:message:colorStyle:)
  public override init(tagline: String?, message: String?, colorStyle: FBTooltipView.ColorStyle) {
    serverConfigurationProvider = ServerConfigurationProvider()
    stringProvider = InternalUtility.shared
    super.init(tagline: tagline, message: message, colorStyle: colorStyle)
  }

  /// Create tooltip
  /// - Parameters:
  ///   - serverConfigurationProvider: Service configuration provider
  ///   - stringProvider: String provider
  init(
    serverConfigurationProvider: ServerConfigurationProviding,
    stringProvider: UserInterfaceStringProviding
  ) {
    self.serverConfigurationProvider = serverConfigurationProvider
    self.stringProvider = stringProvider

    let tooltipMessage = NSLocalizedString(
      "LoginTooltip.Message",
      tableName: "FacebookSDK",
      bundle: stringProvider.bundleForStrings,
      value: "You're in control - choose what info you want to share with apps.",
      comment: "The message of the FBSDKLoginTooltipView"
    )

    super.init(tagline: nil, message: tooltipMessage, colorStyle: .friendlyBlue)
  }

  public override func present(in view: UIView, arrowPosition: CGPoint, direction: FBTooltipView.ArrowDirection) {
    if shouldForceDisplay {
      super.present(in: view, arrowPosition: arrowPosition, direction: direction)
    } else {
      fetchTooltipConfiguration(with: view, arrowPosition: arrowPosition, direction: direction)
    }
  }

  /// Fetch tooltip configuration
  /// - Parameters:
  ///   - view: Target view
  ///   - arrowPosition: Arrow position
  ///   - direction: Arrow direction of tooltip
  private func fetchTooltipConfiguration(
    with view: UIView,
    arrowPosition: CGPoint,
    direction: FBTooltipView.ArrowDirection
  ) {
    serverConfigurationProvider.loadServerConfiguration { loginTooltip, _ in
      guard let loginTooltip = loginTooltip else {
        self.delegate?.loginTooltipViewWillNotAppear?(self)
        return
      }
      self.message = loginTooltip.text

      var shouldDisplay = loginTooltip.isEnabled
      shouldDisplay = self.delegate?.loginTooltipView?(self, shouldAppear: shouldDisplay) ?? shouldDisplay

      if shouldDisplay {
        super.present(in: view, arrowPosition: arrowPosition, direction: direction)
        self.delegate?.loginTooltipViewWillAppear?(self)
      } else {
        self.delegate?.loginTooltipViewWillNotAppear?(self)
      }
    }
  }
}

#endif
