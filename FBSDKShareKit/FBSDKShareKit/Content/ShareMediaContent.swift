/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/// A model for media content (photo or video) to be shared.
@objcMembers
@objc(FBSDKShareMediaContent)
public final class ShareMediaContent: NSObject {

  /// Media to be shared: an array of `SharePhoto` or `ShareVideo`
  public var media = [ShareMedia]()

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

extension ShareMediaContent: SharingContent {
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
    // ShareMediaContent is currently available via the Share extension only
    // (thus no parameterization is implemented at this time)
    existingParameters
  }
}

extension ShareMediaContent: SharingValidation {
  /// Asks the receiver to validate that its content or media values are valid.
  @objc(validateWithOptions:error:)
  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    try _ShareUtility.validateArray(media, minCount: 1, maxCount: 20, named: "photos")

    var hasVideo = false

    try media.forEach { media in
      if let photo = media as? SharePhoto {
        do {
          try photo.validate(options: bridgeOptions)
        } catch {
          throw ErrorFactory().invalidArgumentError(
            domain: ShareErrorDomain,
            name: "media",
            value: photo,
            message: "photos must have UIImages",
            underlyingError: nil
          )
        }
      } else if let video = media as? ShareVideo {
        guard !hasVideo else {
          throw ErrorFactory().invalidArgumentError(
            domain: ShareErrorDomain,
            name: "media",
            value: media,
            message: "Only 1 video is allowed",
            underlyingError: nil
          )
        }

        hasVideo = true

        try _ShareUtility.validateRequiredValue(video, named: "video")
        try video.validate(options: bridgeOptions)
      } else {
        throw ErrorFactory().invalidArgumentError(
          domain: ShareErrorDomain,
          name: "media",
          value: media,
          message: "Only FBSDKSharePhoto and FBSDKShareVideo are allowed in `media` property",
          underlyingError: nil
        )
      }
    }
  }
}
