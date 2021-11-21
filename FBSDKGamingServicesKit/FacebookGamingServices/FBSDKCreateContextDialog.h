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

 #import <FacebookGamingServices/FBSDKContextWebDialog.h>

@class FBSDKCreateContextContent;

NS_ASSUME_NONNULL_BEGIN
/**
  A dialog to create a context through a web view
 */
NS_SWIFT_NAME(CreateContextDialog)
@interface FBSDKCreateContextDialog : FBSDKContextWebDialog

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  Builds a context creation web dialog with content and a delegate.
 @param content The content for the create context dialog
 @param windowFinder The application window finder that provides the window to display the dialog
 @param delegate The receiver's delegate used to let the receiver know a context was created or failure
 */

// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)dialogWithContent:(FBSDKCreateContextContent *)content
                     windowFinder:(id<FBSDKWindowFinding>)windowFinder
                         delegate:(id<FBSDKContextDialogDelegate>)delegate
NS_SWIFT_NAME(init(content:windowFinder:delegate:));
// UNCRUSTIFY_FORMAT_ON

@end
NS_ASSUME_NONNULL_END

#endif
