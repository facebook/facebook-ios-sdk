/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import <UIKit/UIKit.h>

 #import <FBSDKCoreKit/FBSDKCoreKit.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>

 #import "FBSDKLoginProviding.h"

NS_ASSUME_NONNULL_BEGIN

@class FBSDKLoginCompletionParameters;
@class FBSDKLoginManagerLogger;
@class FBSDKPermission;

/**
 Success Block
 */
typedef void (^ FBSDKBrowserLoginSuccessBlock)(BOOL didOpen, NSError *error)
NS_SWIFT_NAME(BrowserLoginSuccessBlock);

typedef NS_ENUM(NSInteger, FBSDKLoginManagerState) {
  FBSDKLoginManagerStateIdle,
  // We received a call to start login.
  FBSDKLoginManagerStateStart,
  // We're calling out to the Facebook app or Safari to perform a log in
  FBSDKLoginManagerStatePerformingLogin,
};

@interface FBSDKLoginManager () <FBSDKURLOpening, FBSDKLoginProviding>
@property (nullable, nonatomic, weak) UIViewController *fromViewController;
@property (nullable, nonatomic, readonly) NSSet<FBSDKPermission *> *requestedPermissions;
@property (nullable, nonatomic, strong) FBSDKLoginManagerLogger *logger;
@property (nullable, nonatomic, strong) FBSDKLoginConfiguration *config;
@property (nonatomic) FBSDKLoginManagerState state;
@property (nonatomic) BOOL usedSFAuthSession;

@property (nullable, nonatomic, readonly, copy) NSString *loadExpectedChallenge;
@property (nullable, nonatomic, readonly, copy) NSString *loadExpectedNonce;

- (void)completeAuthentication:(FBSDKLoginCompletionParameters *)parameters expectChallenge:(BOOL)expectChallenge;

- (void)logIn;

// made available for testing only
- (nullable NSDictionary<NSString *, id> *)logInParametersWithConfiguration:(nullable FBSDKLoginConfiguration *)configuration
                                                               loggingToken:(NSString *)loggingToken
                                                                     logger:(FBSDKLoginManagerLogger *)logger
                                                                 authMethod:(NSString *)authMethod;

// for testing only
- (void)setHandler:(FBSDKLoginManagerLoginResultBlock)handler;
// for testing only
- (void)setRequestedPermissions:(NSSet<NSString *> *)requestedPermissions;

// available to internal modules
- (void)handleImplicitCancelOfLogIn;
- (void)invokeHandler:(nullable FBSDKLoginManagerLoginResult *)result error:(nullable NSError *)error;
- (BOOL)validateLoginStartState;
- (BOOL)isPerformingLogin;
+ (NSString *)stringForChallenge;
- (void)storeExpectedChallenge:(nullable NSString *)expectedChallenge;

@end

#endif

NS_ASSUME_NONNULL_END
