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

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKAuthenticationTokenCreating.h>
 #import <FBSDKLoginKit+Internal/FBSDKAuthenticationTokenFactory.h>
 #import <FBSDKLoginKit+Internal/FBSDKAuthenticationTokenHeader.h>
 #import <FBSDKLoginKit+Internal/FBSDKDevicePoller.h>
 #import <FBSDKLoginKit+Internal/FBSDKDevicePolling.h>
 #import <FBSDKLoginKit+Internal/FBSDKLoginCompletion+Internal.h>
 #import <FBSDKLoginKit+Internal/FBSDKLoginProviding.h>
 #import <FBSDKLoginKit+Internal/FBSDKNonceUtility.h>
 #import <FBSDKLoginKit+Internal/FBSDKPermission.h>
 #import <FBSDKLoginKit+Internal/FBSDKProfileFactory.h>
#else
 #import "FBSDKAuthenticationTokenCreating.h"
 #import "FBSDKAuthenticationTokenFactory.h"
 #import "FBSDKAuthenticationTokenHeader.h"
 #import "FBSDKDevicePoller.h"
 #import "FBSDKDevicePolling.h"
 #import "FBSDKLoginCompletion+Internal.h"
 #import "FBSDKLoginProviding.h"
 #import "FBSDKNonceUtility.h"
 #import "FBSDKPermission.h"
 #import "FBSDKProfileFactory.h"
#endif

#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKLoginManager+Testing.h"
#import "FBSDKSettings+Testing.h"

@protocol FBSDKLoginProviding;

NS_ASSUME_NONNULL_BEGIN

// Categories needed to expose private methods to Swift

@interface FBSDKLoginButton (Testing)

@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

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
- (void)setLoginProvider:(id<FBSDKLoginProviding>)loginProvider;
- (void)_buttonPressed:(id)sender;
- (void)_logout;
- (void)setGraphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestFactory;

@end

@interface FBSDKAccessToken (Testing)

+ (void)setCurrentAccessToken:(nullable FBSDKAccessToken *)token
          shouldDispatchNotif:(BOOL)shouldDispatchNotif;

@end

@interface FBSDKAppEvents (Testing)

+ (void)setSingletonInstanceToInstance:(FBSDKAppEvents *)appEvents;
- (void)logInternalEvent:(FBSDKAppEventName)eventName
              parameters:(NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;
- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds; // expose this since init is NS_UNAVAILABLE

@end

@interface FBSDKProfile (Testing)

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification;

@end

@interface FBSDKAuthenticationToken (Testing)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce;

+ (void)setCurrentAuthenticationToken:(nullable FBSDKAuthenticationToken *)token;

@end

@interface FBSDKDeviceLoginManagerResult (Testing)

- (instancetype)initWithToken:(nullable FBSDKAccessToken *)token
                  isCancelled:(BOOL)cancelled;

@end

@interface FBSDKDeviceLoginManager (Testing)

- (instancetype)initWithPermissions:(NSArray<NSString *> *)permissions enableSmartLogin:(BOOL)enableSmartLogin
                graphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestConnectionFactory
                       devicePoller:(id<FBSDKDevicePolling>)poller;

- (void)_schedulePoll:(NSUInteger)interval;

- (void)setCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo;

- (void)_notifyError:(NSError *)error;

- (void)_notifyToken:(nullable NSString *)tokenString withExpirationDate:(nullable NSDate *)expirationDate withDataAccessExpirationDate:(nullable NSDate *)dataAccessExpirationDate;

- (void)_processError:(NSError *)error;

@end

@interface FBSDKDeviceLoginCodeInfo (Testing)

- (instancetype)initWithIdentifier:(NSString *)identifier
                         loginCode:(NSString *)loginCode
                   verificationURL:(NSURL *)verificationURL
                    expirationDate:(NSDate *)expirationDate
                   pollingInterval:(NSUInteger)pollingInterval;

@end

NS_ASSUME_NONNULL_END
