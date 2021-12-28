/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareMediaContent.h>
#import <FBSDKShareKit/FBSDKSharingValidation.h>
NS_ASSUME_NONNULL_BEGIN

@class FBSDKSharePhoto;
@class PHAsset;

/**
  A video for sharing.
 */
NS_SWIFT_NAME(ShareVideo)
@interface FBSDKShareVideo : NSObject <NSSecureCoding, NSCopying, NSObject, FBSDKShareMedia, FBSDKSharingValidation>

/**
 Convenience method to build a new video object from raw data.
 - Parameter data: The NSData object that holds the raw video data.
 */
+ (instancetype)videoWithData:(NSData *)data;

/**
 Convenience method to build a new video object with NSData and a previewPhoto.
 - Parameter data: The NSData object that holds the raw video data.
 - Parameter previewPhoto: The photo that represents the video.
 */
+ (instancetype)videoWithData:(NSData *)data previewPhoto:(FBSDKSharePhoto *)previewPhoto;

/**
 Convenience method to build a new video object with a PHAsset.
 @param videoAsset The PHAsset that represents the video in the Photos library.
 */
+ (instancetype)videoWithVideoAsset:(PHAsset *)videoAsset;

/**
 Convenience method to build a new video object with a PHAsset and a previewPhoto.
 @param videoAsset The PHAsset that represents the video in the Photos library.
 @param previewPhoto The photo that represents the video.
 */
+ (instancetype)videoWithVideoAsset:(PHAsset *)videoAsset previewPhoto:(FBSDKSharePhoto *)previewPhoto;

/**
  Convenience method to build a new video object with a videoURL.
 @param videoURL The URL to the video.
 */
+ (instancetype)videoWithVideoURL:(NSURL *)videoURL;

/**
  Convenience method to build a new video object with a videoURL and a previewPhoto.
 @param videoURL The URL to the video.
 @param previewPhoto The photo that represents the video.
 */
+ (instancetype)videoWithVideoURL:(NSURL *)videoURL previewPhoto:(FBSDKSharePhoto *)previewPhoto;

/**
 The raw video data.
 - Returns: The video data.
 */
@property (nullable, nonatomic, strong) NSData *data;

/**
 The representation of the video in the Photos library.
 @return PHAsset that represents the video in the Photos library.
 */
@property (nullable, nonatomic, copy) PHAsset *videoAsset;

/**
  The file URL to the video.
 @return URL that points to the location of the video on disk
 */
@property (nullable, nonatomic, copy) NSURL *videoURL;

/**
  The photo that represents the video.
 @return The photo
 */
@property (nullable, nonatomic, copy) FBSDKSharePhoto *previewPhoto;

/**
  Compares the receiver to another video.
 @param video The other video
 @return YES if the receiver's values are equal to the other video's values; otherwise NO
 */
- (BOOL)isEqualToShareVideo:(FBSDKShareVideo *)video;

@end

@interface PHAsset (FBSDKShareVideo)

@property (nonatomic, readonly, copy) NSURL *videoURL;

@end

NS_ASSUME_NONNULL_END
