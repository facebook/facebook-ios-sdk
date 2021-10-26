/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import <FBSDKCoreKit/FBSDKCoreKit.h>
 #import <FBSDKShareKit/FBSDKSharingValidation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 NS_ENUM(NSUInteger, FBSDKAppInviteDestination)
  Specifies the privacy of a group.
 */
typedef NS_ENUM(NSUInteger, FBSDKAppInviteDestination) {
  /** Deliver to Facebook. */
  FBSDKAppInviteDestinationFacebook = 0,
  /** Deliver to Messenger. */
  FBSDKAppInviteDestinationMessenger,
} NS_SWIFT_NAME(AppInviteDestination);

/**
  A model for app invite.
 */
NS_SWIFT_NAME(AppInviteContent)
@interface FBSDKAppInviteContent : NSObject <NSCopying, NSObject, FBSDKSharingValidation, NSSecureCoding>

/**
  A URL to a preview image that will be displayed with the app invite


 This is optional.  If you don't include it a fallback image will be used.
*/
@property (nullable, nonatomic, copy) NSURL *appInvitePreviewImageURL;

/**
  An app link target that will be used as a target when the user accept the invite.


 This is a requirement.
 */
@property (nonatomic, copy) NSURL *appLinkURL;

/**
  Promotional code to be displayed while sending and receiving the invite.


 This is optional. This can be between 0 and 10 characters long and can contain
 alphanumeric characters only. To set a promo code, you need to set promo text.
 */
@property (nullable, nonatomic, copy) NSString *promotionCode;

/**
  Promotional text to be displayed while sending and receiving the invite.


 This is optional. This can be between 0 and 80 characters long and can contain
 alphanumeric and spaces only.
 */
@property (nullable, nonatomic, copy) NSString *promotionText;

/**
  Destination for the app invite.


 This is optional and for declaring destination of the invite.
 */
@property (nonatomic, assign) FBSDKAppInviteDestination destination;

/**
  Compares the receiver to another app invite content.
 @param content The other content
 @return YES if the receiver's values are equal to the other content's values; otherwise NO
 */
- (BOOL)isEqualToAppInviteContent:(FBSDKAppInviteContent *)content;

@end

NS_ASSUME_NONNULL_END

#endif
