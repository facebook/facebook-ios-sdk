/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

#if !os(tvOS)

/**
 A button to share content.

 Tapping the receiver will invoke the FBSDKShareDialog with the attached shareContent.  If the dialog cannot
 be shown, the button will be disabled.
 */
@objcMembers
@objc(FBSDKShareButton)
public final class FBShareButton: FBButton, SharingButton {
  var dialog: ShareDialog?

  public var shareContent: SharingContent? {
    get { dialog?.shareContent }
    set {
      dialog?.shareContent = newValue
      checkImplicitlyDisabled()
    }
  }

  public var analyticsParameters: [AppEvents.ParameterName: Any]? { nil }

  public var impressionTrackingEventName: AppEvents.Name { .shareButtonImpression }

  public var impressionTrackingIdentifier: String { "share" }

  public override var isImplicitlyDisabled: Bool {
    guard let dialog = dialog else { return true }

    if !dialog.canShow {
      return true
    } else {
      do {
        try dialog.validate()
        return false
      } catch {
        return true
      }
    }
  }

  public func configureButton() {
    var title = ""
    if let bundle = Self.stringProvider?.bundleForStrings {
      title = NSLocalizedString(
        "ShareButton.Share",
        tableName: "FacebookSDK",
        bundle: bundle,
        value: "Share",
        comment: "The label for FBSDKShareButton"
      )
    }

    configure(
      with: nil,
      title: title,
      backgroundColor: nil,
      highlightedColor: nil
    )
    addTarget(
      self,
      action: #selector(Self.share),
      for: .touchUpInside
    )
    dialog = ShareDialog(viewController: nil, content: nil, delegate: nil)
  }

  // swiftlint:disable:next private_action
  @IBAction func share() {
    logTapEvent(
      withEventName: .shareButtonDidTap,
      parameters: analyticsParameters
    )

    dialog?.show()
  }
}

// MARK: - Type dependencies

extension FBShareButton: DependentAsType {
  struct TypeDependencies {
    var stringProvider: UserInterfaceStringProviding
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(stringProvider: InternalUtility.shared)
}

#endif
