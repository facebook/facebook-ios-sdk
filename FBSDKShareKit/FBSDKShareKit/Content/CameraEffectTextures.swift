/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

#if !os(tvOS)

/**
 * A container of textures for a camera effect.
 * A texture for a camera effect is an UIImages identified by a NSString key.
 */
@objcMembers
@objc(FBSDKCameraEffectTextures)
public final class CameraEffectTextures: NSObject {

  private(set) var textures = [String: UIImage]()

  /**
   Sets the image for a texture key.
   @param image The `UIImage` for the texture
   @param key The key for the texture
   */
  @objc(setImage:forKey:)
  public func set(_ image: UIImage?, forKey key: String) {
    textures[key] = image
  }

  /**
   Gets the image for a texture key.
   @param key The key for the texture
   @return The texture `UIImage` or nil
   */
  @objc(imageForKey:)
  public func image(forKey key: String) -> UIImage? {
    textures[key]
  }
}

#endif
