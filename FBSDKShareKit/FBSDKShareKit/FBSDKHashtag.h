/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
  Represents a single hashtag that can be used with the share dialog.
 */
NS_SWIFT_NAME(Hashtag)
@interface FBSDKHashtag : NSObject <NSCopying, NSObject, NSSecureCoding>

/**
  Convenience method to build a new hashtag with a string identifier. Equivalent to setting the
   `stringRepresentation` property.
 @param hashtagString The hashtag string.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)hashtagWithString:(NSString *)hashtagString
NS_SWIFT_NAME(init(_:));
// UNCRUSTIFY_FORMAT_ON

/**
  The hashtag string.

 You are responsible for making sure that `stringRepresentation` is a valid hashtag (a single '#' followed
   by one or more word characters). Invalid hashtags are ignored when sharing content. You can check validity with the
   `valid` property.
 @return The hashtag string.
 */
@property (nonatomic, copy) NSString *stringRepresentation;

/**
  Tests if a hashtag is valid.

 A valid hashtag matches the regular expression "#\w+": A single '#' followed by one or more
   word characters.
 @return YES if the hashtag is valid, NO otherwise.
 */
@property (nonatomic, readonly, getter = isValid, assign) BOOL valid;

/**
  Compares the receiver to another hashtag.
 @param hashtag The other hashtag
 @return YES if the receiver is equal to the other hashtag; otherwise NO
 */
- (BOOL)isEqualToHashtag:(FBSDKHashtag *)hashtag;

@end

NS_ASSUME_NONNULL_END
