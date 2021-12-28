/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

 #import <FacebookGamingServices/FBSDKContextWebDialog.h>
 #import <FacebookGamingServices/FBSDKDialogProtocol.h>

typedef NS_ENUM(NSInteger, FBSDKChooseContextFilter);

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

// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(content:delegate:));
// UNCRUSTIFY_FORMAT_ON

/**
 Convenience method to build up a choose context app switch with content , a delegate and a utility object.
 @param content The content for the choose context dialog
 @param delegate The receiver's delegate.
 @param internalUtility The dialog's utility used to build the url and decide how to display the dialog
 */

// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(id<FBSDKContextDialogDelegate>)delegate
                  internalUtility:(id<FBSDKInternalUtility>)internalUtility
NS_SWIFT_NAME(init(content:delegate:internalUtility:));
// UNCRUSTIFY_FORMAT_ON

@end
NS_ASSUME_NONNULL_END

#endif
