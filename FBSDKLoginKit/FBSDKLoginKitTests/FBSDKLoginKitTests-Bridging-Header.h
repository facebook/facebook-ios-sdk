/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;
- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds; // expose this since init is NS_UNAVAILABLE

@end

@interface FBSDKProfile (Testing)

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification;

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
