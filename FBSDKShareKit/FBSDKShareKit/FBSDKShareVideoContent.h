/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKShareKit/FBSDKSharePhoto.h>
#import <FBSDKShareKit/FBSDKShareVideo.h>
#import <FBSDKShareKit/FBSDKSharingContent.h>

NS_ASSUME_NONNULL_BEGIN

/**
  A model for video content to be shared.
 */
NS_SWIFT_NAME(ShareVideoContent)
@interface FBSDKShareVideoContent : NSObject <FBSDKSharingContent>

/**
  The video to be shared.
 @return The video
 */
@property (nonatomic, copy) FBSDKShareVideo *video;

/**
  Compares the receiver to another video content.
 @param content The other content
 @return YES if the receiver's values are equal to the other content's values; otherwise NO
 */
- (BOOL)isEqualToShareVideoContent:(FBSDKShareVideoContent *)content;

@end

NS_ASSUME_NONNULL_END
