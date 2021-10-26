/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import "FBSDKLoginManager+Internal.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Native;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Browser;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_SFVC;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Applink;

NS_SWIFT_NAME(LoginManagerLogger)
@interface FBSDKLoginManagerLogger : NSObject
+ (nullable FBSDKLoginManagerLogger *)loggerFromParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                  tracking:(FBSDKLoginTracking)tracking;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithLoggingToken:(nullable NSString *)loggingToken
                                     tracking:(FBSDKLoginTracking)tracking
  NS_DESIGNATED_INITIALIZER;

// this must not retain loginManager - only used to conveniently grab various properties to log.
- (void)startSessionForLoginManager:(FBSDKLoginManager *)loginManager;
- (void)endSession;

- (void)startAuthMethod:(NSString *)authMethod;
- (void)endLoginWithResult:(nullable FBSDKLoginManagerLoginResult *)result error:(nullable NSError *)error;

- (void)postLoginHeartbeat;

+ (nullable NSString *)clientStateForAuthMethod:(nullable NSString *)authMethod
                               andExistingState:(nullable NSDictionary<NSString *, id> *)existingState
                                         logger:(nullable FBSDKLoginManagerLogger *)logger;

- (void)willAttemptAppSwitchingBehavior;

- (void)logNativeAppDialogResult:(BOOL)result dialogDuration:(NSTimeInterval)dialogDuration;

@end

#endif

NS_ASSUME_NONNULL_END
