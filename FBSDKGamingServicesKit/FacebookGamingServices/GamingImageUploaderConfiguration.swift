/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
@objc(FBSDKGamingImageUploaderConfiguration)
public class GamingImageUploaderConfiguration: NSObject {
  public private(set) var image: UIImage
  public private(set) var caption: String?
  public private(set) var shouldLaunchMediaDialog: Bool

  /**
   A model for Gaming image upload content to be shared.

   @param image the image that will be shared.
   @param caption and optional caption that will appear along side the image on Facebook.
   @param shouldLaunchMediaDialog whether or not to open the media dialog on Facebook when the upload completes.
   */

  public init(
    image: UIImage,
    caption: String?,
    shouldLaunchMediaDialog: Bool
  ) {
    self.image = image
    self.caption = caption
    self.shouldLaunchMediaDialog = shouldLaunchMediaDialog
  }
}
