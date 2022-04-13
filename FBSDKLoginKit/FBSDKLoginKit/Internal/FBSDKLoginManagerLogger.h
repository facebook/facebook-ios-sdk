/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

 #import "FBSDKLoginManager+Internal.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Native;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Browser;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_SFVC;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Applink;

NS_SWIFT_NAME(LoginManagerLogger)
@interface FBSDKLoginManagerLogger : NSObject

// UNCRUSTIFY_FORMAT_OFF
+ (nullable FBSDKLoginManagerLogger *)loggerFromParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                  tracking:(FBSDKLoginTracking)tracking
NS_SWIFT_NAME(init(parameters:tracking:));
// UNCRUSTIFY_FORMAT_ON

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// UNCRUSTIFY_FORMAT_OFF
- (nullable instancetype)initWithLoggingToken:(nullable NSString *)loggingToken
                                     tracking:(FBSDKLoginTracking)tracking
NS_DESIGNATED_INITIALIZER
NS_SWIFT_NAME(init(loggingToken:tracking:));
// UNCRUSTIFY_FORMAT_ON

// this must not retain loginManager - only used to conveniently grab various properties to log.
- (void)startSessionForLoginManager:(FBSDKLoginManager *)loginManager;
- (void)endSession;

- (void)startAuthMethod:(NSString *)authMethod;
- (void)endLoginWithResult:(nullable FBSDKLoginManagerLoginResult *)result error:(nullable NSError *)error;

- (void)postLoginHeartbeat;

+ (nullable NSString *)clientStateForAuthMethod:(nullable NSString *)authMethod
                               andExistingState:(nullable NSDictionary<NSString *, id> *)existingState
                                         logger:(nullable FBSDKLoginManagerLogger *)logger;

- (void)willAttemptAppSwitchingBehaviorWithUrlScheme:(NSString *)urlScheme;

- (void)logNativeAppDialogResult:(BOOL)result dialogDuration:(NSTimeInterval)dialogDuration;

@end

#endif

NS_ASSUME_NONNULL_END
