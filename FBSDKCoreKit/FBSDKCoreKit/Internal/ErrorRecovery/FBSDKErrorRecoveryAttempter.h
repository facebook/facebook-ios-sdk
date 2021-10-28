/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKConstants.h>
#import <FBSDKCoreKit/FBSDKErrorRecoveryAttempting.h>

@class FBSDKErrorRecoveryConfiguration;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ErrorRecoveryAttempter)
@interface FBSDKErrorRecoveryAttempter : NSObject <FBSDKErrorRecoveryAttempting>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// can return nil if configuration is not supported.
+ (nullable instancetype)recoveryAttempterFromConfiguration:(FBSDKErrorRecoveryConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
