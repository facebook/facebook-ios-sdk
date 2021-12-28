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

/**
  A model for status and link content to be shared.
 */
NS_SWIFT_NAME(ShareLinkContent)
@interface FBSDKShareLinkContent : NSObject <FBSDKSharingContent>

/**
  Some quote text of the link.

 If specified, the quote text will render with custom styling on top of the link.
 @return The quote text of a link
 */
@property (nullable, nonatomic, copy) NSString *quote;

/**
  Compares the receiver to another link content.
 @param content The other content
 @return YES if the receiver's values are equal to the other content's values; otherwise NO
 */
- (BOOL)isEqualToShareLinkContent:(FBSDKShareLinkContent *)content;

@end

NS_ASSUME_NONNULL_END
