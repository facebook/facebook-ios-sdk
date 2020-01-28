// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if TARGET_OS_TV

// This is an unfortunate hack for Swift Package Manager support.
// SPM does not allow us to conditionally exclude Swift files for compilation by platform.
//
// So to support tvOS with SPM we need to use runtime availability checks in the Swift files.
// This means that even though the Swift extension of ShareDialog will never be run for tvOS
// targets, it still needs to be able to compile. Hence we need to declare it here.
//
// The way to fix this is to remove extensions of ObjC types in Swift.
// This will be be done in the next major release (6.0)

NS_SWIFT_NAME(ShareDialog)
@interface FBSDKShareDialog : NSObject
@end

#else

#import <UIKit/UIKit.h>

#import "FBSDKShareDialogMode.h"
#import "FBSDKSharing.h"
#import "FBSDKSharingContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
  A dialog for sharing content on Facebook.
 */
NS_SWIFT_NAME(ShareDialog)
@interface FBSDKShareDialog : NSObject <FBSDKSharingDialog>

/**
  Convenience method to create a FBSDKShareDialog with a fromViewController, content and a delegate.
 @param viewController A UIViewController to present the dialog from, if appropriate.
 @param content The content to be shared.
 @param delegate The receiver's delegate.
 */
+ (instancetype)dialogWithViewController:(nullable UIViewController *)viewController
                             withContent:(id<FBSDKSharingContent>)content
                                delegate:(nullable id<FBSDKSharingDelegate>)delegate
NS_SWIFT_NAME(init(fromViewController:content:delegate:));

/**
 Convenience method to show an FBSDKShareDialog with a fromViewController, content and a delegate.
 @param viewController A UIViewController to present the dialog from, if appropriate.
 @param content The content to be shared.
 @param delegate The receiver's delegate.
 */
+ (instancetype)showFromViewController:(UIViewController *)viewController
                           withContent:(id<FBSDKSharingContent>)content
                              delegate:(nullable id<FBSDKSharingDelegate>)delegate
NS_SWIFT_UNAVAILABLE("Use init(fromViewController:content:delegate:).show() instead");

/**
  A UIViewController to present the dialog from.

 If not specified, the top most view controller will be automatically determined as best as possible.
 */
@property (nonatomic, weak) UIViewController *fromViewController;

/**
  The mode with which to display the dialog.

 Defaults to FBSDKShareDialogModeAutomatic, which will automatically choose the best available mode.
 */
@property (nonatomic, assign) FBSDKShareDialogMode mode;

@end

NS_ASSUME_NONNULL_END

#endif
