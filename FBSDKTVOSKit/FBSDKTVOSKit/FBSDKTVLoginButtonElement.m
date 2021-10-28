/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTVLoginButtonElement.h"

@implementation FBSDKTVLoginButtonElement

#pragma mark - FBSDKDeviceLoginButtonDelegate

- (void)deviceLoginButtonDidCancel:(FBSDKDeviceLoginButton *)button
{
  [self dispatchEventWithName:@"onFacebookLoginCancel"
                    canBubble:YES
                  cancellable:YES
                    extraInfo:nil
                   completion:NULL];
}

- (void)deviceLoginButton:(FBSDKDeviceLoginButton *)button didFailWithError:(NSError *)error
{
  [self dispatchEventWithName:@"onFacebookLoginError"
                    canBubble:YES
                  cancellable:YES
                    extraInfo:@{ @"error" : error }
                   completion:NULL];
}

- (void)deviceLoginButtonDidLogIn:(FBSDKDeviceLoginButton *)button
{
  [self dispatchEventWithName:@"onFacebookLogin"
                    canBubble:YES
                  cancellable:YES
                    extraInfo:nil
                   completion:NULL];
}

- (void)deviceLoginButtonDidLogOut:(FBSDKDeviceLoginButton *)button
{
  [self dispatchEventWithName:@"onFacebookLogout"
                    canBubble:YES
                  cancellable:YES
                    extraInfo:nil
                   completion:NULL];
}

@end
