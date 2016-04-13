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
@interface FBSDKTVLoginButtonElement : TVViewElement <FBSDKDeviceLoginButtonDelegate>

@end

NS_ASSUME_NONNULL_END
