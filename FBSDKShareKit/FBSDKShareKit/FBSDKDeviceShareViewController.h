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

#import <FBSDKCoreKit/FBSDKDeviceViewControllerBase.h>

#import <FBSDKShareKit/FBSDKSharingContent.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKDeviceShareViewController;

/**
  A delegate for `FBSDKDeviceShareViewController`
 */
@protocol FBSDKDeviceShareViewControllerDelegate <NSObject>

/**
  Indicates the dialog was completed

 This can happen if the user tapped cancel, or menu on their Siri remote, or if the
  device code has expired. You will not be informed if the user actually posted a share to Facebook.
 */
- (void)deviceShareViewControllerDidComplete:(FBSDKDeviceShareViewController *)viewController error:(nullable NSError *)error;

@end

/**
  Use this view controller to initiate Sharing for Devices, an easy way for people to share content
  from your tvOS app without requiring Facebook Login.

 The `FBSDKDeviceShareViewController` can dismiss itself and notify its delegate
 of completion. You should not re-use a `FBSDKDeviceShareViewController` instance again.

 See [Sharing for Devices](https://developers.facebook.com/docs/sharing/for-devices).

 @code
 // from your view controller:
 FBSDKDeviceShareViewController *vc = [[FBSDKDeviceShareViewController alloc] initWithShareContent:...];
 vc.delegate = self;
 [self presentViewController:vc
                    animated:YES
                  completion:NULL];
 */
@interface FBSDKDeviceShareViewController : FBSDKDeviceViewControllerBase

/**
  Initializes a new instance with share content.
 - Parameter shareContent: The share content. Only `FBSDKShareLinkContent` and `FBSDKShareOpenGraphContent` are supported.

 Invalid content types will result in notifying the delegate with an error when the view controller is presented.

 For `FBSDKShareLinkContent`, only contentURL is used (e.g., <FBSDKSharingContent> properties are not supported)
 For `FBSDKShareOpenGraphContent`, only the action is used (e.g., <FBSDKSharingContent> properties are not supported).
 */
- (instancetype)initWithShareContent:(id<FBSDKSharingContent>)shareContent NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil  NS_UNAVAILABLE;

/**
  The delegate.
 */
@property (nullable, nonatomic, weak) id<FBSDKDeviceShareViewControllerDelegate> delegate;

/**
  The share content.
 */
@property (nonatomic, readonly, strong) id<FBSDKSharingContent> shareContent;

@end

NS_ASSUME_NONNULL_END
