/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import Foundation
import UIKit

/// A model for content to share with a Facebook camera effect.
@objcMembers
@objc(FBSDKShareCameraEffectContent)
public final class ShareCameraEffectContent: NSObject {

  /// ID of the camera effect to use.
  public var effectID = ""

  /// Arguments for the effect.
  public var effectArguments = CameraEffectArguments()

  /// Textures for the effect.
  public var effectTextures = CameraEffectTextures()

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

extension ShareCameraEffectContent: DependentAsType {
  struct TypeDependencies {
    var internalUtility: InternalUtilityProtocol
    var errorFactory: ErrorCreating
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    internalUtility: InternalUtility.shared,
    errorFactory: ErrorFactory()
  )
}

// MARK: - Sharing

extension ShareCameraEffectContent: SharingContent {

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
    updatedParameters["effect_id"] = effectID

    if let jsonString = try? BasicUtility.jsonString(
      for: effectArguments.arguments,
      invalidObjectHandler: nil
    ) {
      updatedParameters["effect_arguments"] = jsonString
    }

    // Convert the entire textures dictionary into one data instance, because
    // the existing API protocol only allows one value to be put into the pasteboard.

    // Convert UIImages to NSData, because UIImage is not archivable.
    let textureImageData = effectTextures.textures.compactMapValues(UIImage.pngData)

    if let serializedTextureImages = try? NSKeyedArchiver.archivedData(
      withRootObject: textureImageData,
      requiringSecureCoding: true
    ) {
      updatedParameters["effect_textures"] = serializedTextureImages
    }

    return updatedParameters
  }

  @objc(validateWithOptions:error:)
  public func validate(options bridgeOptions: ShareBridgeOptions) throws {
    guard !effectID.isEmpty else { return }

    if !CharacterSet(charactersIn: effectID).isSubset(of: .decimalDigits) {
      let errorFactory = try Self.getDependencies().errorFactory
      throw errorFactory.invalidArgumentError(
        name: "effectID",
        value: effectID,
        message: "Invalid value for effectID, effectID can contain only numerical characters.",
        underlyingError: nil
      )
    }
  }
}

#endif
