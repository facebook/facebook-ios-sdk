/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKShareKit/FBSDKSharingContent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A protocol for media content (photo or video) to be shared.
 */
NS_SWIFT_NAME(ShareMedia)
@protocol FBSDKShareMedia <NSObject>

@end

/**
  A model for media content (photo or video) to be shared.
 */
NS_SWIFT_NAME(ShareMediaContent)
@interface FBSDKShareMediaContent : NSObject <FBSDKSharingContent>

/**
  Media to be shared.
 @return Array of the media (FBSDKSharePhoto or FBSDKShareVideo)
 */
@property (nonatomic, copy) NSArray<id<FBSDKShareMedia>> *media;

/**
  Compares the receiver to another media content.
 @param content The other content
 @return YES if the receiver's values are equal to the other content's values; otherwise NO
 */
- (BOOL)isEqualToShareMediaContent:(FBSDKShareMediaContent *)content;

@end

NS_ASSUME_NONNULL_END
