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

@class FBSDKSharePhoto;

/**
  A model for photo content to be shared.
 */
NS_SWIFT_NAME(SharePhotoContent)
@interface FBSDKSharePhotoContent : NSObject <FBSDKSharingContent>

/**
  Photos to be shared.
 @return Array of the photos (FBSDKSharePhoto)
 */
@property (nonatomic, copy) NSArray<FBSDKSharePhoto *> *photos;

/**
  Compares the receiver to another photo content.
 @param content The other content
 @return YES if the receiver's values are equal to the other content's values; otherwise NO
 */
- (BOOL)isEqualToSharePhotoContent:(FBSDKSharePhotoContent *)content;

@end

NS_ASSUME_NONNULL_END
