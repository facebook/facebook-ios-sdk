/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKShareKit/FBSDKShareConstants.h>
#import <FBSDKShareKit/FBSDKSharing.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A dialog for sharing content through Messenger.

 SUPPORTED SHARE TYPES
 - FBSDKShareLinkContent

 UNSUPPORTED SHARE TYPES (DEPRECATED AUGUST 2018)
 - FBSDKShareOpenGraphContent
 - FBSDKSharePhotoContent
 - FBSDKShareVideoContent
 - FBSDKShareMessengerOpenGraphMusicTemplateContent
 - FBSDKShareMessengerMediaTemplateContent
 - FBSDKShareMessengerGenericTemplateContent
 - Any other types that are not one of the four supported types listed above
 */
NS_SWIFT_NAME(MessageDialog)
@interface FBSDKMessageDialog : NSObject <FBSDKSharingDialog>

/**
 Convenience initializer to return a Message Share Dialog with content and a delegate.
 @param content The content to be shared.
 @param delegate The receiver's delegate.
 */
- (instancetype)initWithContent:(nullable id<FBSDKSharingContent>)content
                       delegate:(nullable id<FBSDKSharingDelegate>)delegate;

/**
 Convenience method to return a Message Share Dialog with content and a delegate.
 @param content The content to be shared.
 @param delegate The receiver's delegate.
 */
+ (instancetype)dialogWithContent:(nullable id<FBSDKSharingContent>)content
                         delegate:(nullable id<FBSDKSharingDelegate>)delegate
  NS_SWIFT_UNAVAILABLE("Use init(content:delegate:) instead");

/**
 Convenience method to show a Message Share Dialog with content and a delegate.
 @param content The content to be shared.
 @param delegate The receiver's delegate.
 */
+ (instancetype)showWithContent:(nullable id<FBSDKSharingContent>)content
                       delegate:(nullable id<FBSDKSharingDelegate>)delegate
  NS_SWIFT_UNAVAILABLE("Use init(content:delegate:).show() instead");

@end

NS_ASSUME_NONNULL_END

#endif
