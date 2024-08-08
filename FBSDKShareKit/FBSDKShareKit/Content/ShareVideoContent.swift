/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import Photos

/// A model for video content to be shared.
@objcMembers
@objc(FBSDKShareVideoContent)
public final class ShareVideoContent: NSObject {

  /// The video to be shared
  public var video = ShareVideo()

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
  public private(set) var shareUUID: String? = UUID().uuidString
}

// MARK: - Type Dependencies

extension ShareVideoContent: DependentAsType {
  struct TypeDependencies {
    var validator: ShareValidating.Type
    var mediaLibrarySearcher: MediaLibrarySearching
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    validator: _ShareUtility.self,
    mediaLibrarySearcher: PHImageManager.default()
  )
}

// MARK: - Sharing Content

extension ShareVideoContent: SharingContent {

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
    var videoParameters = [String: Any]()

    if let asset = video.videoAsset {
      videoParameters["assetIdentifier"] = asset.localIdentifier
    } else if let data = video.data {
      if bridgeOptions == .videoData {
        // Bridge the data
        videoParameters["data"] = data
      }
    } else if let url = video.videoURL {
      if url.scheme?.lowercased() == "assets-library" {
        // Bridge the legacy "assets-library" URL
        videoParameters["assetURL"] = url
      } else if url.isFileURL {
        if bridgeOptions == .videoData,
           // Load the contents of the file and bridge the data
           let data = try? Data(contentsOf: url, options: .mappedIfSafe) {
          videoParameters["data"] = data
        }
      }
    }

    if let photo = video.previewPhoto {
      videoParameters["previewPhoto"] = photo
    }

    updatedParameters["video"] = videoParameters
    return updatedParameters
  }
}

extension ShareVideoContent: SharingValidatable {
  @objc(validateWithOptions:error:)
  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    let validator = try Self.getDependencies().validator
    try validator.validateRequiredValue(video, named: "video")
    try video.validate(options: bridgeOptions)
  }
}
