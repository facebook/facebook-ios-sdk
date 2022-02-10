/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKDeviceLoginViewController;

/// A delegate for `FBSDKDeviceLoginViewController`
NS_SWIFT_NAME(DeviceLoginViewControllerDelegate)
@protocol FBSDKDeviceLoginViewControllerDelegate <NSObject>

/// Indicates the login was cancelled or timed out.
- (void)deviceLoginViewControllerDidCancel:(FBSDKDeviceLoginViewController *)viewController;

/// Indicates the login finished. The `FBSDKAccessToken.currentAccessToken` will be set.
- (void)deviceLoginViewControllerDidFinish:(FBSDKDeviceLoginViewController *)viewController;

/// Indicates an error with the login.
- (void)deviceLoginViewController:(FBSDKDeviceLoginViewController *)viewController didFailWithError:(NSError *)error;

@end

/**
 Use this view controller to initiate a Facebook Device Login.
 The `FBSDKDeviceLoginViewController` will dismiss itself and notify its delegate
  of the results. You should not re-use a `FBSDKDeviceLoginViewController` instance again.

  Upon success, `FBSDKAccessToken.currentAccessToken` will be set.

  See [Facebook Device Login]( https://developers.facebook.com/docs/facebook-login/for-devices ).

 @code
 // from your view controller:
 FBSDKDeviceLoginViewController *vc = [FBSDKDeviceLoginViewController new];
 vc.delegate = self;
 [self presentViewController:vc
                    animated:YES
                  completion:NULL];
 */
NS_SWIFT_NAME(FBDeviceLoginViewController)
@interface FBSDKDeviceLoginViewController : FBSDKDeviceViewControllerBase

/// The delegate.
@property (nullable, nonatomic, weak) id<FBSDKDeviceLoginViewControllerDelegate> delegate;

/**
 The permissions to request.
 To provide the best experience, you should minimize the number of permissions you request, and only ask for them when needed.
 For example, do not ask for "user_location" until you the information is actually used by the app.

 Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.

 See [the permissions guide]( https://developers.facebook.com/docs/facebook-login/permissions/ ) for more details.
 */
@property (nonatomic, copy) NSArray<NSString *> *permissions;

/**
 The optional URL to redirect the user to after they complete the login.
 The URL must be configured in your App Settings -> Advanced -> OAuth Redirect URIs
 */
@property (nullable, nonatomic, copy) NSURL *redirectURL;

@end

NS_ASSUME_NONNULL_END
