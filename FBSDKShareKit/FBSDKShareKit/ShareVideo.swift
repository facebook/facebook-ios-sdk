/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation
import Photos

/// A video for sharing.
@objcMembers
@objc(FBSDKShareVideo)
public final class ShareVideo: NSObject, ShareMedia {

  // This property maintains a single source for the video: raw data, an asset or a URL
  private var source: Source? {
    didSet {
      previewPhoto = nil
    }
  }

  /// The raw video data.
  public var data: Data? {
    get { source?.data }
    set { source = Source(newValue) }
  }

  /// The representation of the video in the Photos library.
  public var videoAsset: PHAsset? {
    get { source?.asset }
    set { source = Source(newValue) }
  }

  /// The file URL to the video.
  public var videoURL: URL? {
    get { source?.url }
    set { source = Source(newValue) }
  }

  /// The photo that represents the video.
  public var previewPhoto: SharePhoto?

  /**
   Convenience method to build a new video object from raw data and an optional preview photo.
   - Parameter data: The Data object that holds the raw video data.
   - Parameter previewPhoto: The photo that represents the video.
   */
  public convenience init(
    data: Data,
    previewPhoto: SharePhoto? = nil
  ) {
    self.init(source: .data(data), previewPhoto: previewPhoto)
  }

  /**
   Convenience method to build a new video object from a PHAsset and an optional preview photo.
   - Parameter videoAsset: The PHAsset that represents the video in the Photos library.
   - Parameter previewPhoto: The photo that represents the video.
   */
  public convenience init(
    videoAsset: PHAsset,
    previewPhoto: SharePhoto? = nil
  ) {
    self.init(source: .asset(videoAsset), previewPhoto: previewPhoto)
  }

  /**
   Convenience method to build a new video object from a URL and an optional preview photo.
   - Parameter videoURL: The URL to the video.
   - Parameter previewPhoto: The photo that represents the video.
   */
  public convenience init(
    videoURL: URL,
    previewPhoto: SharePhoto? = nil
  ) {
    self.init(source: .url(videoURL), previewPhoto: previewPhoto)
  }

  init(
    source: Source? = nil,
    previewPhoto: SharePhoto? = nil
  ) {
    super.init()

    self.source = source
    self.previewPhoto = previewPhoto
  }
}

extension ShareVideo: SharingValidation {
  /// Asks the receiver to validate that its content or media values are valid.
  @objc(validateWithOptions:error:)
  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    // Validate that a valid asset, data, or videoURL value has been set.
    // Don't validate the preview photo -- if it isn't valid it'll be dropped from the share.
    // A default one may be created if needed.
    switch source {
    case let .asset(asset):
      try validateVideoAsset(asset, options: bridgeOptions)
    case let .data(data):
      try validateData(data, options: bridgeOptions)
    case let .url(url):
      try validateVideoURL(url, options: bridgeOptions)
    default:
      throw ErrorFactory().invalidArgumentError(
        domain: ShareErrorDomain,
        name: "video",
        value: self,
        message: "Must have an asset, data, or videoURL value.",
        underlyingError: nil
      )
    }
  }

  private func validateData(_ data: Data, options bridgeOptions: ShareBridgeOptions) throws {
    guard bridgeOptions == .videoData else {
      throw ErrorFactory().invalidArgumentError(
        domain: ShareErrorDomain,
        name: "data",
        value: data,
        message: "Cannot share video data.",
        underlyingError: nil
      )
    }
  }

  private func validateVideoAsset(_ asset: PHAsset, options bridgeOptions: ShareBridgeOptions) throws {
    guard asset.mediaType == .video else {
      throw ErrorFactory().invalidArgumentError(
        domain: ShareErrorDomain,
        name: "videoAsset",
        value: videoAsset,
        message: "Must refer to a video file.",
        underlyingError: nil
      )
    }

    // Will bridge the PHAsset.localIdentifier or the legacy "assets-library" URL from AVAsset
  }

  private func validateVideoURL(_ videoURL: URL, options bridgeOptions: ShareBridgeOptions) throws {
    if videoURL.scheme?.lowercased() == "assets-library" {
      // Will bridge the legacy "assets-library" URL
      return
    } else if videoURL.isFileURL,
              bridgeOptions == .videoData {
      // Will load the contents of the file and bridge the data
      return
    }

    throw ErrorFactory().invalidArgumentError(
      domain: ShareErrorDomain,
      name: "videoURL",
      value: videoURL,
      message: "Must refer to an asset file.",
      underlyingError: nil
    )
  }
}

extension ShareVideo {
  // This helps us make sure that only one type of source is used
  enum Source {
    case data(Data)
    case url(URL)
    case asset(PHAsset)

    var data: Data? {
      switch self {
      case let .data(data): return data
      default: return nil
      }
    }

    var url: URL? {
      switch self {
      case let .url(url): return url
      default: return nil
      }
    }

    var asset: PHAsset? {
      switch self {
      case let .asset(asset): return asset
      default: return nil
      }
    }

    init?(_ data: Data?) {
      guard let data = data else { return nil }

      self = .data(data)
    }

    init?(_ url: URL?) {
      guard let url = url else { return nil }

      self = .url(url)
    }

    init?(_ asset: PHAsset?) {
      guard let asset = asset else { return nil }

      self = .asset(asset)
    }
  }
}
