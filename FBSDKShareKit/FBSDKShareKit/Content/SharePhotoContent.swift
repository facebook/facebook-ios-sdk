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

// MARK: - Class Dependencies

extension SharePhotoContent: DependentType {
  struct Dependencies {
    var imageFinder: MediaLibrarySearching
    var validator: ShareValidating.Type
  }

  static var configuredDependencies: Dependencies?

  static let defaultDependencies: Dependencies? = Dependencies(
    imageFinder: PHImageManager.default(),
    validator: _ShareUtility.self
  )
}

// MARK: - SharingContent

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
    guard let imageFinder = try? Self.getDependencies().imageFinder else {
      return existingParameters
    }

    var images = [UIImage]()

    photos.forEach { photo in
      if let asset = photo.photoAsset {
        if let image = try? imageFinder.fb_findImage(for: asset) {
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

// MARK: - SharingValidation

extension SharePhotoContent: SharingValidation {
  // The number of photos that can be shared at once is restricted
  private static let photosCountRange = 1 ... 6

  /// Validate that this content contains valid values
  @objc(validateWithOptions:error:)
  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    let validator = try Self.getDependencies().validator
    try validator.validateArray(
      photos,
      minCount: Self.photosCountRange.lowerBound,
      maxCount: Self.photosCountRange.upperBound,
      named: "photos"
    )

    try photos.forEach { photo in
      try photo.validate(options: bridgeOptions)
    }
  }
}
