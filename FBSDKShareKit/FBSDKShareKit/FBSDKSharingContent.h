/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKSharingValidation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKHashtag;

/**
  A base interface for content to be shared.
 */
NS_SWIFT_NAME(SharingContent)
@protocol FBSDKSharingContent <NSCopying, NSObject, FBSDKSharingValidation, NSSecureCoding>

/**
  URL for the content being shared.

 This URL will be checked for all link meta tags for linking in platform specific ways.  See documentation
 for App Links (https://developers.facebook.com/docs/applinks/)
 @return URL representation of the content link
 */
@property (nonatomic, copy) NSURL *contentURL;

/**
  Hashtag for the content being shared.
 @return The hashtag for the content being shared.
 */
@property (nullable, nonatomic, copy) FBSDKHashtag *hashtag;

/**
  List of IDs for taggable people to tag with this content.
  See documentation for Taggable Friends
 (https://developers.facebook.com/docs/graph-api/reference/user/taggable_friends)
 @return Array of IDs for people to tag (NSString)
 */
@property (nonatomic, copy) NSArray<NSString *> *peopleIDs;

/**
  The ID for a place to tag with this content.
 @return The ID for the place to tag
 */
@property (nullable, nonatomic, copy) NSString *placeID;

/**
  A value to be added to the referrer URL when a person follows a link from this shared content on feed.
 @return The ref for the content.
 */
@property (nullable, nonatomic, copy) NSString *ref;

/**
 For shares into Messenger, this pageID will be used to map the app to page and attach attribution to the share.
 @return The ID of the Facebook page this share is associated with.
 */
@property (nullable, nonatomic, copy) NSString *pageID;

/**
 A unique identifier for a share involving this content, useful for tracking purposes.
 @return A unique string identifying this share data.
 */
@property (nullable, nonatomic, readonly, copy) NSString *shareUUID;

/**
 Adds content to an existing dictionary as key/value pairs and returns the
 updated dictionary
 @param existingParameters An immutable dictionary of existing values
 @param bridgeOptions The options for bridging
 @return A new dictionary with the modified contents
 */

// UNCRUSTIFY_FORMAT_OFF
- (NSDictionary<NSString *, id> *)addParameters:(NSDictionary<NSString *, id> *)existingParameters
                                  bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
NS_SWIFT_NAME(addParameters(_:options:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
