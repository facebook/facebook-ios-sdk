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
