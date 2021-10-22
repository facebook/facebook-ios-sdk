/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

@class FBSDKChooseContextContent;
@protocol FBSDKInternalUtility;

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <FacebookGamingServices/FBSDKDialogProtocol.h>
#import <FacebookGamingServices/FBSDKContextWebDialog.h>

NS_ASSUME_NONNULL_BEGIN
/**
  A dialog for the choose context through app switch
 */
NS_SWIFT_NAME(ChooseContextDialog)
@interface FBSDKChooseContextDialog : FBSDKContextWebDialog

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Convenience method to build up a choose context app switch with content and a delegate.
 @param content The content for the choose context dialog
 @param delegate The receiver's delegate.
 */
+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(content:delegate:));

/**
 Convenience method to build up a choose context app switch with content , a delegate and a utility object.
 @param content The content for the choose context dialog
 @param delegate The receiver's delegate.
 @param internalUtility The dialog's utility used to build the url and decide how to display the dialog
 */
+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(id<FBSDKContextDialogDelegate>)delegate
                  internalUtility:(id<FBSDKInternalUtility>)internalUtility
NS_SWIFT_NAME(init(content:delegate:internalUtility:));


@end
NS_ASSUME_NONNULL_END

#endif
