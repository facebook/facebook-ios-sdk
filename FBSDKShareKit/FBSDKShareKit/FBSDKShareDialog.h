/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

// This is an unfortunate hack for Swift Package Manager support.
// SPM does not allow us to conditionally exclude Swift files for compilation by platform.
//
// So to support tvOS with SPM we need to use runtime availability checks in the Swift files.
// This means that even though the Swift extension of ShareDialog will never be run for tvOS
// targets, it still needs to be able to compile. Hence we need to declare it here.
//
// The way to fix this is to remove extensions of ObjC types in Swift.

NS_SWIFT_NAME(ShareDialog)
@interface FBSDKShareDialog : NSObject
@end

#else

 #import <UIKit/UIKit.h>

 #import <FBSDKShareKit/FBSDKShareDialogMode.h>
 #import <FBSDKShareKit/FBSDKSharing.h>
 #import <FBSDKShareKit/FBSDKSharingContent.h>

NS_ASSUME_NONNULL_BEGIN

/**
  A dialog for sharing content on Facebook.
 */
NS_SWIFT_NAME(ShareDialog)
@interface FBSDKShareDialog : NSObject <FBSDKSharingDialog>

- (instancetype)init NS_UNAVAILABLE
  DEPRECATED_MSG_ATTRIBUTE("`init` is deprecated and will be removed in the next major release. Please use one of the other available initializers");
+ (instancetype)new NS_UNAVAILABLE
  DEPRECATED_MSG_ATTRIBUTE("`new` is deprecated and will be removed in the next major release. Please use one of the other available initializers");

/**
  Convenience initializer to initialize an `FBSDKShareDialog` with a view controller, content and delegate.
 @param viewController A view controller from which to present the dialog, if appropriate.
 @param content The content to be shared.
 @param delegate The dialog's delegate.
 */
- (instancetype)initWithViewController:(nullable UIViewController *)viewController
                               content:(nullable id<FBSDKSharingContent>)content
                              delegate:(nullable id<FBSDKSharingDelegate>)delegate;

/**
  Convenience method to create an `FBSDKShareDialog` with a view controller, content and delegate.
 @param viewController A view controller from which to present the dialog, if appropriate.
 @param content The content to be shared.
 @param delegate The dialog's delegate.
 */
+ (instancetype)dialogWithViewController:(nullable UIViewController *)viewController
                             withContent:(nullable id<FBSDKSharingContent>)content
                                delegate:(nullable id<FBSDKSharingDelegate>)delegate
  NS_SWIFT_UNAVAILABLE("Use `init(viewController:content:delegate:)");

/**
 Convenience method to show an `FBSDKShareDialog` with a view controller, content and delegate.
 @param viewController A view controller from which to present the dialog, if appropriate.
 @param content The content to be shared.
 @param delegate The dialog's delegate.
 */
+ (instancetype)showFromViewController:(nullable UIViewController *)viewController
                           withContent:(nullable id<FBSDKSharingContent>)content
                              delegate:(nullable id<FBSDKSharingDelegate>)delegate
  NS_SWIFT_UNAVAILABLE("Use init(viewController:content:delegate:).show() instead");

/**
  A UIViewController from which to present the dialog.

 If not specified, the topmost view controller will be automatically determined as best as possible.
 */
@property (nonatomic, weak) UIViewController *fromViewController;

/**
  The mode with which to display the dialog.

 Defaults to `FBSDKShareDialogModeAutomatic`, which will automatically choose the best available mode.
 */
@property (nonatomic, assign) FBSDKShareDialogMode mode;

@end

NS_ASSUME_NONNULL_END

#endif
