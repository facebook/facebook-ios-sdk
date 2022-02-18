/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import Foundation

/// A model for app invite
@objcMembers
@objc(FBSDKAppInviteContent)
public final class AppInviteContent: NSObject {

  /// Specifies the privacy of a group.
  @objc(FBSDKAppInviteDestination)
  public enum Destination: Int {
    /// Deliver to Facebook
    case facebook

    // Deliver to Messenger
    case messenger
  }

  /**
   A URL to a preview image that will be displayed with the app invite

   This is optional.  If you don't include it a fallback image will be used.
   */
  public var appInvitePreviewImageURL: URL?

  /// An app link target that will be used as a target when the user accept the invite.
  public var appLinkURL: URL

  /**
   Promotional code to be displayed while sending and receiving the invite.

   This is optional. This can be between 0 and 10 characters long and can contain
   alphanumeric characters only. To set a promo code, you need to set promo text.
   */
  public var promotionCode: String?

  /**
   Promotional text to be displayed while sending and receiving the invite.

   This is optional. This can be between 0 and 80 characters long and can contain
   alphanumeric and spaces only.
   */
  public var promotionText: String?

  /// Destination for the app invite.  The default value is `.facebook`.
  public var destination = Destination.facebook

  @objc(initWithAppLinkURL:)
  public init(appLinkURL: URL) {
    self.appLinkURL = appLinkURL
  }
}

extension AppInviteContent: SharingValidation {

  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    try _ShareUtility.validateNetworkURL(appLinkURL, named: "appLinkURL")

    if let url = appInvitePreviewImageURL {
      try _ShareUtility.validateNetworkURL(url, named: "appInvitePreviewImageURL")
    }

    try validatePromoCode()
  }

  private func validatePromoCode() throws {
    let textIsEmpty = promotionText?.isEmpty ?? true
    let codeIsEmpty = promotionCode?.isEmpty ?? true
    guard !textIsEmpty || !codeIsEmpty else { return }

    let errorFactory: ErrorCreating = ErrorFactory()

    guard let text = promotionText,
          (1 ... 80).contains(text.count)
    else {
      throw errorFactory.invalidArgumentError(
        name: "promotionText",
        value: promotionText,
        message: "Invalid value for promotionText; promotionText has to be between 1 and 80 characters long.",
        underlyingError: nil
      )
    }

    guard (promotionCode?.count ?? 0) <= 10 else {
      throw errorFactory.invalidArgumentError(
        name: "promotionCode",
        value: promotionCode,
        message: """
          Invalid value for promotionCode; promotionCode has to be between 0 and 10 characters long \
          and is required when promoCode is set.
          """,
        underlyingError: nil
      )
    }

    let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces)

    guard CharacterSet(charactersIn: text).isSubset(of: allowedCharacters) else {
      throw errorFactory.invalidArgumentError(
        name: "promotionText",
        value: text,
        message: "Invalid value for promotionText; promotionText can contain only alphanumeric characters and spaces.",
        underlyingError: nil
      )
    }

    guard let code = promotionCode else { return }

    if !CharacterSet(charactersIn: code).isSubset(of: allowedCharacters) {
      throw errorFactory.invalidArgumentError(
        name: "promotionCode",
        value: code,
        message: "Invalid value for promotionCode; promotionCode can contain only alphanumeric characters and spaces.",
        underlyingError: nil
      )
    }
  }
}

#endif
