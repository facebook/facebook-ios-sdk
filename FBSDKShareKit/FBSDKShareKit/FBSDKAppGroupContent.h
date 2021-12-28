/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_TV

typedef NS_ENUM(NSUInteger, AppGroupPrivacy) { AppGroupPrivacyOpen, };

FOUNDATION_EXPORT NSString *NSStringFromFBSDKAppGroupPrivacy(AppGroupPrivacy privacy)
NS_REFINED_FOR_SWIFT;

#else

 #import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 NS_ENUM(NSUInteger, FBSDKAppGroupPrivacy)
  Specifies the privacy of a group.
 */
typedef NS_ENUM(NSUInteger, FBSDKAppGroupPrivacy) {
  /** Anyone can see the group, who's in it and what members post. */
  FBSDKAppGroupPrivacyOpen = 0,
  /** Anyone can see the group and who's in it, but only members can see posts. */
  FBSDKAppGroupPrivacyClosed,
} NS_SWIFT_NAME(AppGroupPrivacy);

/**
  Converts an FBSDKAppGroupPrivacy to an NSString.
 */
FOUNDATION_EXPORT NSString *NSStringFromFBSDKAppGroupPrivacy(FBSDKAppGroupPrivacy privacy)
NS_REFINED_FOR_SWIFT;

/**
  A model for creating an app group.
 */
NS_SWIFT_NAME(AppGroupContent)
@interface FBSDKAppGroupContent : NSObject <NSCopying, NSObject, NSSecureCoding>

/**
  The description of the group.
 */
@property (nonatomic, copy) NSString *groupDescription;

/**
  The name of the group.
 */
@property (nonatomic, copy) NSString *name;

/**
  The privacy for the group.
 */
@property (nonatomic, assign) FBSDKAppGroupPrivacy privacy;

/**
  Compares the receiver to another app group content.
 @param content The other content
 @return YES if the receiver's values are equal to the other content's values; otherwise NO
 */
- (BOOL)isEqualToAppGroupContent:(FBSDKAppGroupContent *)content;

@end

NS_ASSUME_NONNULL_END

#endif
