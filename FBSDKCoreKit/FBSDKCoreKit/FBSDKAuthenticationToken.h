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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

/**
  Notification indicating that the `currentAuthenticationToken` has changed.

 the userInfo dictionary of the notification will contain keys
 `FBSDKAuthenticationTokenChangeOldKey` and
 `FBSDKAuthenticationTokenChangeNewKey`.
 */
FOUNDATION_EXPORT NSNotificationName const FBSDKAuthenticationTokenDidChangeNotification
NS_SWIFT_NAME(AuthenticationTokenDidChange);

#else

/**
  Notification indicating that the `currentAuthenticationToken` has changed.

 the userInfo dictionary of the notification will contain keys
 `FBSDKAuthenticationTokenChangeOldKey` and
 `FBSDKAuthenticationTokenChangeNewKey`.
 */
FOUNDATION_EXPORT NSString *const FBSDKAuthenticationTokenDidChangeNotification
NS_SWIFT_NAME(AuthenticationTokenDidChange);

#endif

/**
 A key in the `AuthenticationTokenDidChange` notification's userInfo object for getting the old token.

 If there was no old token, the key will not be present.
 */
FOUNDATION_EXPORT NSString *const FBSDKAuthenticationTokenChangeOldKey
NS_SWIFT_NAME(AuthenticationTokenChangeOldKey);

/**
 A key in `AuthenticationTokenDidChange` notification's userInfo object for getting the new token.

 If there is no new token, the key will not be present.
 */
FOUNDATION_EXPORT NSString *const FBSDKAuthenticationTokenChangeNewKey
NS_SWIFT_NAME(AuthenticationTokenChangeNewKey);

/**
 Represent an AuthenticationToken used for a login attempt
*/
NS_SWIFT_NAME(AuthenticationToken)
@interface FBSDKAuthenticationToken : NSObject<NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  The "global" authentication token that represents the currently logged in user.

 The `currentAuthenticationToken` represents the authentication token of the
 current user and can be used by a client to verify an authentication attempt.
 */
@property (class, nonatomic, copy, nullable) FBSDKAuthenticationToken *currentAuthenticationToken;

/**
 The raw token string from the authentication response
 */
@property (nonatomic, copy, readonly) NSString *tokenString;

/**
 The nonce from the decoded authentication response
 */
@property (nonatomic, copy, readonly) NSString *nonce;

/**
 Initializes a new instance if the token represented by the token string is valid. Otherwise returns nil.
 An `AuthenticationToken` is verified based of the OpenID Connect Protocol.
 @param tokenString the raw ID token string
 @param nonce the nonce string used to associate a client session with the token
*/
- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce;

@end

NS_ASSUME_NONNULL_END
