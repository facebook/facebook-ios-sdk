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
 A button to send content through Messenger.

 Tapping the receiver will invoke the FBSDKShareDialog with the attached shareContent.  If the dialog cannot
 be shown, the button will be disable.
 */
@objcMembers
@objc(FBSDKSendButton)
public final class FBSendButton: FBButton, SharingButton, FBButtonImpressionLogging {
  public var dialog: MessageDialog?

  public var shareContent: SharingContent? {
    get { dialog?.shareContent }
    set {
      dialog?.shareContent = newValue
      checkImplicitlyDisabled()
    }
  }

  public var analyticsParameters: [AppEvents.ParameterName: Any]? { nil }

  public var impressionTrackingEventName: AppEvents.Name { .sendButtonImpression }

  public var impressionTrackingIdentifier: String { "send" }

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
    if let internalUtility = Self.internalUtility {
      title = NSLocalizedString(
        "SendButton.Send",
        tableName: "FacebookSDK",
        bundle: internalUtility.bundleForStrings,
        value: "Send",
        comment: "The label for FBSDKSendButton"
      )
    }

    let backgroundColor = UIColor(red: 0.0, green: 132.0 / 255.0, blue: 1.0, alpha: 1.0)
    let highlightedColor = UIColor(red: 0.0, green: 111.0 / 255.0, blue: 1.0, alpha: 1.0)

    configure(
      with: MessengerIcon(),
      title: title,
      backgroundColor: backgroundColor,
      highlightedColor: highlightedColor
    )
    addTarget(
      self,
      action: #selector(Self.share),
      for: .touchUpInside
    )
    dialog = MessageDialog()
  }

  // swiftlint:disable:next private_action
  @IBAction func share() {
    logTapEvent(
      withEventName: .sendButtonDidTap,
      parameters: analyticsParameters
    )

    dialog?.show()
  }
}

extension FBSendButton: DependentAsType {
  struct TypeDependencies {
    var internalUtility: InternalUtilityProtocol
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(internalUtility: InternalUtility.shared)
}

#endif
