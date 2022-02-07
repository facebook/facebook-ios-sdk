/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

@end

NS_ASSUME_NONNULL_END
