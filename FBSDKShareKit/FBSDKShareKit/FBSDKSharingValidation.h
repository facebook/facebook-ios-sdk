/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Flags to indicate support for newer bridge options beyond the initial 20130410 implementation.
 */
typedef NS_OPTIONS(NSUInteger, FBSDKShareBridgeOptions) {
  FBSDKShareBridgeOptionsDefault = 0,
  FBSDKShareBridgeOptionsPhotoAsset = 1 << 0,
  FBSDKShareBridgeOptionsPhotoImageURL = 1 << 1, // if set, a web-based URL is required; asset, image, and imageURL.isFileURL not allowed
  FBSDKShareBridgeOptionsVideoAsset = 1 << 2,
  FBSDKShareBridgeOptionsVideoData = 1 << 3,
  FBSDKShareBridgeOptionsWebHashtag = 1 << 4, // if set, pass the hashtag as a string value, not an array of one string
} NS_SWIFT_NAME(ShareBridgeOptions);

/**
 A base interface for validation of content and media.
 */
NS_SWIFT_NAME(SharingValidation)
@protocol FBSDKSharingValidation

/**
 Asks the receiver to validate that its content or media values are valid.
 - Parameter errorRef: Optional, will receive an FBSDKShareError if the values are not valid.
 - Returns: YES if the receiver's values are valid; otherwise NO
 */
- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef;

@end

NS_ASSUME_NONNULL_END
