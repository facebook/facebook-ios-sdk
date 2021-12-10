/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKTVOSKit/FBSDKDeviceLoginButton.h>
#import <TVMLKit/TVViewElement.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract Represents a <FBSDKLoginButton /> tag in TVML.
 @discussion You should not need to use this class directly. Instead, make sure you
 initialize a `FBSDKTVInterfaceFactory` instance correctly.

 This element can dispatch the following events to Javascript, which map to corresponding
 messages of `FBSDKDeviceLoginButtonDelegate`.
 - `onFacebookLogin`
 - `onFacebookLogout`
 - `onFacebookLoginCancel`
 - `onFacebookLoginError`

 These events can bubble up the DOM.

 The '<FBSDKLoginButton />' tag can also have the following attributes:
 - either a `readPermissions` or (not both) `publishPermissions` attribute whose value is a comma delimited
 list of permissions to request.
 - `redirectURL` an optional URL to redirect the user to after completing the login.

 */
NS_SWIFT_NAME(FBTVLoginButtonElement)
@interface FBSDKTVLoginButtonElement : TVViewElement <FBSDKDeviceLoginButtonDelegate>

@end

NS_ASSUME_NONNULL_END
