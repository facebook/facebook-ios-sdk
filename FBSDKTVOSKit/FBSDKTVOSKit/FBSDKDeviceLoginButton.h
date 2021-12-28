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

@protocol FBSDKDeviceLoginButtonDelegate;

/*!
 @abstract A button that initiates a log in or log out flow upon tapping.
 @discussion `FBSDKLoginButton` works with `[FBSDKAccessToken currentAccessToken]` to
 determine what to display, and automatically starts authentication (by presenting
 `FBSDKDeviceLoginViewController`) when tapped (i.e., you do not need to manually
 subscribe action targets).

 `FBSDKLoginButton` has an instrinsic size and you should avoid changing its dimensions. `initWithFrame:CGRectZero`
 will size the button to its desired frame.
 */
NS_SWIFT_NAME(FBDeviceLoginButton)
@interface FBSDKDeviceLoginButton : FBSDKDeviceButton

/*!
 @abstract Gets or sets the delegate.
 */
@property (nullable, nonatomic, weak) IBOutlet id<FBSDKDeviceLoginButtonDelegate> delegate;

/*!
 @abstract The permissions to request.
 @discussion To provide the best experience, you should minimize the number of permissions you request, and only ask for them when needed.
 For example, do not ask for "user_location" until you the information is actually used by the app.

 Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.

 See [the permissions guide]( https://developers.facebook.com/docs/facebook-login/permissions/ ) for more details.
 */
@property (nonatomic, copy) NSArray<NSString *> *permissions;

/*!
 @abstract the optional URL to redirect the user to after they complete the login.
 @discussion the URL must be configured in your App Settings -> Advanced -> OAuth Redirect URIs
 */
@property (nullable, nonatomic, copy) NSURL *redirectURL;

@end

/*!
 @protocol
 @abstract A delegate protocol for `FBSDKDeviceLoginButton`
 */
NS_SWIFT_NAME(DeviceLoginButtonDelegate)
@protocol FBSDKDeviceLoginButtonDelegate <NSObject>

/*!
 @abstract Indicates the login was cancelled or timed out.
 */
- (void)deviceLoginButtonDidCancel:(FBSDKDeviceLoginButton *)button;

/*!
 @abstract Indicates the login finished. The `FBSDKAccessToken.currentAccessToken` will be set.
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)deviceLoginButtonDidLogIn:(FBSDKDeviceLoginButton *)button
NS_SWIFT_NAME(deviceLoginButtonDidLogIn(_:));
// UNCRUSTIFY_FORMAT_ON

/*!
 @abstract Indicates the logout finished. The `FBSDKAccessToken.currentAccessToken` will be nil.
 */
- (void)deviceLoginButtonDidLogOut:(FBSDKDeviceLoginButton *)button;

/*!
 @abstract Indicates an error with the login.
 */
- (void)deviceLoginButton:(FBSDKDeviceLoginButton *)button didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
