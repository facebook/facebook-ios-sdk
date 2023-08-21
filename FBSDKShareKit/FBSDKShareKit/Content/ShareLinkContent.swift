/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// A model for status and link content to be shared.
@objcMembers
@objc(FBSDKShareLinkContent)
public final class ShareLinkContent: NSObject {

  /**
   Some quote text of the link.

   If specified, the quote text will render with custom styling on top of the link.
   */
  public var quote: String?

  /**
   URL for the content being shared.

   This URL will be checked for all link meta tags for linking in platform specific ways.  See documentation
   for App Links (https://developers.facebook.com/docs/applinks/)
   */
  public var contentURL: URL?

  /// Hashtag for the content being shared.
  public var hashtag: Hashtag?

  /**
   List of IDs for taggable people to tag with this content.

   See documentation for Taggable Friends
   (https://developers.facebook.com/docs/graph-api/reference/user/taggable_friends)
   */
  public var peopleIDs = [String]()

  /// The ID for a place to tag with this content.
  public var placeID: String?

  /// A value to be added to the referrer URL when a person follows a link from this shared content on feed.
  public var ref: String?

  /// For shares into Messenger, this pageID will be used to map the app to page and attach attribution to the share.
  public var pageID: String?

  /// A unique identifier for a share involving this content, useful for tracking purposes.
  public let shareUUID: String? = UUID().uuidString
}

extension ShareLinkContent: SharingContent {
  /**
   Adds content to an existing dictionary as key/value pairs and returns the
   updated dictionary
   @param existingParameters An immutable dictionary of existing values
   @param bridgeOptions The options for bridging
   @return A new dictionary with the modified contents
   */
  @objc(addParameters:bridgeOptions:)
  public func addParameters(
    _ existingParameters: [String: Any],
    options bridgeOptions: ShareBridgeOptions
  ) -> [String: Any] {
    var updatedParameters = existingParameters

    if let url = contentURL {
      updatedParameters["link"] = url
      // Pass link parameter as "messenger_link" due to versioning requirements for message dialog flow.
      // We will only use the new share flow we developed if messenger_link is present, not link.
      updatedParameters["messenger_link"] = url
    }
    if let quote = quote {
      updatedParameters["quote"] = quote
    }

    return updatedParameters
  }
}

extension ShareLinkContent: SharingValidatable {
  /// Asks the receiver to validate that its content or media values are valid.
  @objc(validateWithOptions:error:)
  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    guard let url = contentURL else { return }

    try _ShareUtility.validateNetworkURL(url, named: "contentURL")
  }
}
