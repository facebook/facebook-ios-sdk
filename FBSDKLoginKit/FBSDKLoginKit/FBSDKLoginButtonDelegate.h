/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 @protocol
 A delegate for `FBSDKLoginButton`
 */
NS_SWIFT_NAME(LoginButtonDelegate)
@protocol FBSDKLoginButtonDelegate <NSObject>

@required
/**
 Sent to the delegate when the button was used to login.
 @param loginButton The sender
 @param result The results of the login
 @param error The error (if any) from the login
 */
- (void)    loginButton:(FBSDKLoginButton *)loginButton
  didCompleteWithResult:(nullable FBSDKLoginManagerLoginResult *)result
                  error:(nullable NSError *)error;

/**
 Sent to the delegate when the button was used to logout.
 @param loginButton The button that was clicked.
 */
- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton;

@optional
/**
 Sent to the delegate when the button is about to login.
 @param loginButton The sender
 @return YES if the login should be allowed to proceed, NO otherwise
 */
- (BOOL)loginButtonWillLogin:(FBSDKLoginButton *)loginButton;

@end

NS_ASSUME_NONNULL_END
