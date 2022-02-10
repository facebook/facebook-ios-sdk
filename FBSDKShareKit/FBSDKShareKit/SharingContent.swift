/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/// A base interface for content to be shared.
@objc(FBSDKSharingContent)
public protocol SharingContent: NSObjectProtocol, SharingValidation {

  /**
   URL for the content being shared.

   This URL will be checked for all link meta tags for linking in platform specific ways.
   See documentation for App Links (https://developers.facebook.com/docs/applinks/)
   */
  var contentURL: URL? { get set }

  /// Hashtag for the content being shared.
  var hashtag: Hashtag? { get set }

  /**
   List of IDs for taggable people to tag with this content.

   See documentation for Taggable Friends
   (https://developers.facebook.com/docs/graph-api/reference/user/taggable_friends)
   */
  var peopleIDs: [String] { get set }

  /// The ID for a place to tag with this content.
  var placeID: String? { get set }

  /// A value to be added to the referrer URL when a person follows a link from this shared content on feed.
  var ref: String? { get set }

  /// For shares into Messenger, this pageID will be used to map the app to page and attach attribution to the share.
  var pageID: String? { get set }

  /// A unique identifier for a share involving this content, useful for tracking purposes.
  var shareUUID: String? { get }

  /**
   Adds content to an existing dictionary as key/value pairs and returns the
   updated dictionary
   @param existingParameters An immutable dictionary of existing values
   @param bridgeOptions The options for bridging
   @return A new dictionary with the modified contents
   */
  @objc(addParameters:bridgeOptions:)
  func addParameters(
    _ existingParameters: [String: Any],
    options bridgeOptions: ShareBridgeOptions
  ) -> [String: Any]
}
