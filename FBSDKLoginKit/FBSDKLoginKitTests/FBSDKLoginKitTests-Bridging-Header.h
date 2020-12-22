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

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "FBSDKCoreKit+Internal.h"

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKGraphRequestConnectionProviding.h>
 #import <FBSDKLoginKit+Internal/FBSDKNonceUtility.h>
#else
 #import "FBSDKGraphRequestConnectionProviding.h"
 #import "FBSDKNonceUtility.h"
#endif

@class FBSDKAuthenticationTokenClaims;

NS_ASSUME_NONNULL_BEGIN

// Categories needed to expose private methods to Swift

@interface FBSDKLoginButton (Testing)

- (FBSDKLoginConfiguration *)loginConfiguration;
- (BOOL)_isAuthenticated;
- (void)_fetchAndSetContent;
- (void)_initializeContent;
- (void)_updateContentForAccessToken;
- (void)_updateContentForUserProfile:(nullable FBSDKProfile *)profile;
- (void)_accessTokenDidChangeNotification:(NSNotification *)notification;
- (void)_profileDidChangeNotification:(NSNotification *)notification;
- (nullable NSString *)userName;
- (nullable NSString *)userID;

@end

@interface FBSDKAccessToken (Testing)

+ (void)setCurrentAccessToken:(nullable FBSDKAccessToken *)token
          shouldDispatchNotif:(BOOL)shouldDispatchNotif;

@end

@interface FBSDKProfile (Testing)

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification;

@end

@interface FBSDKAuthenticationToken (Testing)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                             claims:(nullable FBSDKAuthenticationTokenClaims *)claims
                                jti:(NSString *)jti;

+ (void)setCurrentAuthenticationToken:(nullable FBSDKAuthenticationToken *)token
               shouldPostNotification:(BOOL)shouldPostNotification;

@end

NS_ASSUME_NONNULL_END
