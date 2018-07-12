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

import FBSDKShareKit
import Foundation

/**
 A model for an app invite.
 */
public struct AppInvite: Equatable {

  /// An app link target that will be used as a target when the user accepts the invite.
  public var appLink: URL

  /// The delivery method for this app invite.
  public var deliveryMethod: DeliveryMethod

  /// The URL to a preview image that will be displayed with the app invite.
  public var previewImageURL: URL?

  /// The promotional code and text to be displayed while sending and recieving the invite.
  public var promotion: (code: PromoCode, text: String)?

  /**
   Create an `AppInvite` with a link, delivery method, preview image, and promotion.

   - parameter appLink: The app link target.
   - parameter deliveryMethod: Optonal delivery method to use. Default: `.Facebook`.
   - parameter previewImageURL: Optional preview image to use. Default: `nil`.
   - parameter promotion: Optional promotion to be displayed. Default: `nil`.
   */
  public init(appLink: URL,
              deliveryMethod: DeliveryMethod = .facebook,
              previewImageURL: URL? = nil,
              promotion: (code: PromoCode, text: String)? = nil) {
    self.appLink = appLink
    self.deliveryMethod = deliveryMethod
    self.previewImageURL = previewImageURL
    self.promotion = promotion
  }

  // MARK: Equatable

  /**
   Compare two `AppInvite`s for equality.

   - parameter lhs: The first invite to compare.
   - parameter rhs: The second invite to compare.

   - returns: Whether or not the invites are equal.
   */
  public static func == (lhs: AppInvite, rhs: AppInvite) -> Bool {
    return lhs.sdkInviteRepresentation == rhs.sdkInviteRepresentation
  }

  // MARK: Internal

  internal var sdkInviteRepresentation: FBSDKAppInviteContent {
    let sdkContent = FBSDKAppInviteContent()
    sdkContent.appLinkURL = appLink
    sdkContent.appInvitePreviewImageURL = previewImageURL
    sdkContent.promotionCode = promotion?.code.rawValue
    sdkContent.promotionText = promotion?.text
    sdkContent.destination = deliveryMethod.sdkDestinationRepresentation

    return sdkContent
  }
}
