/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import <UIKit/UIKit.h>

 #import <FBSDKCoreKit/FBSDKCoreKit.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>

 #import "FBSDKLoginCompleterFactoryProtocol.h"
 #import "FBSDKLoginCompletionParameters.h"
 #import "FBSDKLoginProviding.h"

NS_ASSUME_NONNULL_BEGIN

@class FBSDKLoginManagerLogger;
@class FBSDKPermission;

/// Success Block
typedef void (^ FBSDKBrowserLoginSuccessBlock)(BOOL didOpen, NSError *error)
NS_SWIFT_NAME(BrowserLoginSuccessBlock);

typedef NS_ENUM(NSInteger, FBSDKLoginManagerState) {
  FBSDKLoginManagerStateIdle,
  // We received a call to start login.
  FBSDKLoginManagerStateStart,
  // We're calling out to the Facebook app or Safari to perform a log in
  FBSDKLoginManagerStatePerformingLogin,
};

@interface FBSDKLoginManager () <FBSDKURLOpening>

@property (nullable, nonatomic) FBSDKLoginManagerLoginResultBlock handler;
@property (nullable, nonatomic) FBSDKLoginConfiguration *configuration;
@property (nonatomic) id<FBSDKKeychainStore> keychainStore;
@property (nonatomic) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> accessTokenWallet;
@property (nonatomic) Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting> authenticationToken;
@property (nonatomic) Class<FBSDKProfileProviding> profile;
@property (nonatomic) id<FBSDKURLHosting, FBSDKAppURLSchemeProviding, FBSDKAppAvailabilityChecker> internalUtility;
@property (nonatomic) id<FBSDKURLOpener> urlOpener;
@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) id<FBSDKLoginCompleterFactory> loginCompleterFactory;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

@property (nullable, nonatomic, weak) UIViewController *fromViewController;
@property (nullable, nonatomic, readonly) NSSet<FBSDKPermission *> *requestedPermissions;
@property (nullable, nonatomic, strong) FBSDKLoginManagerLogger *logger;
@property (nullable, nonatomic, strong) FBSDKLoginConfiguration *config;
@property (nonatomic) FBSDKLoginManagerState state;
@property (nonatomic) BOOL usedSFAuthSession;
@property (nonatomic, readonly) BOOL isPerformingLogin;

@property (nullable, nonatomic, readonly, copy) NSString *loadExpectedChallenge;
@property (nullable, nonatomic, readonly, copy) NSString *loadExpectedNonce;

- (instancetype)initWithInternalUtility:(id<FBSDKURLHosting, FBSDKAppURLSchemeProviding, FBSDKAppAvailabilityChecker>)internalUtility
                   keychainStoreFactory:(id<FBSDKKeychainStoreProviding>)keychainStoreFactory
                      accessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)accessTokenWallet
                    authenticationToken:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationToken
                                profile:(Class<FBSDKProfileProviding>)profile
                              urlOpener:(id<FBSDKURLOpener>)urlOpener
                               settings:(id<FBSDKSettings>)settings
                  loginCompleterFactory:(id<FBSDKLoginCompleterFactory>)loginCompleterFactory
                    graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
;

- (void)completeAuthentication:(FBSDKLoginCompletionParameters *)parameters expectChallenge:(BOOL)expectChallenge;

- (void)logIn;

// made available for testing only
- (nullable NSDictionary<NSString *, NSString *> *)logInParametersWithConfiguration:(nullable FBSDKLoginConfiguration *)configuration
                                                                       loggingToken:(nullable NSString *)loggingToken
                                                                             logger:(nullable FBSDKLoginManagerLogger *)logger
                                                                         authMethod:(NSString *)authMethod;

// for testing only
- (void)setHandler:(FBSDKLoginManagerLoginResultBlock)handler;
// for testing only
- (void)setRequestedPermissions:(NSSet<NSString *> *)requestedPermissions;

// available to internal modules
- (void)handleImplicitCancelOfLogIn;
- (void)invokeHandler:(nullable FBSDKLoginManagerLoginResult *)result error:(nullable NSError *)error;
- (BOOL)validateLoginStartState;
+ (NSString *)stringForChallenge;
- (void)storeExpectedChallenge:(nullable NSString *)expectedChallenge;

@end

#endif

NS_ASSUME_NONNULL_END
