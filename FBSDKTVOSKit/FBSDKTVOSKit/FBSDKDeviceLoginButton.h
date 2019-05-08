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

#import <FBSDKCoreKit/FBSDKDeviceButton.h>

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
- (void)deviceLoginButtonDidLogIn:(FBSDKDeviceLoginButton *)button
NS_SWIFT_NAME(deviceLoginButtonDidLogIn(_:));

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
