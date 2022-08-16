/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

/**
 FBSDKProfilePictureMode enum
  Defines the aspect ratio mode for the source image of the profile picture.
 */
typedef NS_ENUM(NSUInteger, FBSDKProfilePictureMode) {
  /// A square cropped version of the image will be included in the view.
  FBSDKProfilePictureModeSquare,
  /// The original picture's aspect ratio will be used for the source image in the view.
  FBSDKProfilePictureModeNormal,
  /// The original picture's aspect ratio will be used for the source image in the view.
  FBSDKProfilePictureModeAlbum,
  /// The original picture's aspect ratio will be used for the source image in the view.
  FBSDKProfilePictureModeSmall,
  /// The original picture's aspect ratio will be used for the source image in the view.
  FBSDKProfilePictureModeLarge,
} NS_SWIFT_NAME(Profile.PictureMode);

#endif
