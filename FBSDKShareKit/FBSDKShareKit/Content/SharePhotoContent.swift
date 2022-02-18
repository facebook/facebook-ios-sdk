/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import Photos
import UIKit

/// A model for photo content to be shared.
@objcMembers
@objc(FBSDKSharePhotoContent)
public final class SharePhotoContent: NSObject {

  /// Photos to be shared.
  public var photos = [SharePhoto]()

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

extension SharePhotoContent: SharingContent {
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
    var images = [UIImage]()

    photos.forEach { photo in
      if let asset = photo.photoAsset {
        // Load the asset and bridge the image
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.resizeMode = .exact
        imageRequestOptions.deliveryMode = .highQualityFormat
        imageRequestOptions.isSynchronous = true

        PHImageManager.default().requestImage(
          for: asset,
          targetSize: PHImageManagerMaximumSize,
          contentMode: .default,
          options: imageRequestOptions
        ) { potentialImage, _ in
          guard let image = potentialImage else { return }

          images.append(image)
        }
      } else if let url = photo.imageURL {
        // Load the contents of the file and bridge the image
        if url.isFileURL,
           let image = UIImage(contentsOfFile: url.path) {
          images.append(image)
        }
      } else if let image = photo.image {
        // Bridge the image
        images.append(image)
      }
    }

    var updatedParameters = existingParameters
    if !images.isEmpty {
      updatedParameters["photos"] = images
    }

    return updatedParameters
  }
}

extension SharePhotoContent: SharingValidation {
  private struct UnknownValidationError: Error {}

  /// Asks the receiver to validate that its content or media values are valid.
  @objc(validateWithOptions:error:)
  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    try _ShareUtility.validateArray(photos, minCount: 1, maxCount: 6, named: "photos")

    try photos.forEach { photo in
      try photo.validate(options: bridgeOptions)
    }
  }
}
