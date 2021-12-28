/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKConstants.h>

NS_ASSUME_NONNULL_BEGIN

// immutable
NS_SWIFT_NAME(ErrorRecoveryConfiguration)
@interface FBSDKErrorRecoveryConfiguration : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly) NSString *localizedRecoveryDescription;
@property (nonatomic, readonly) NSArray<NSString *> *localizedRecoveryOptionDescriptions;
@property (nonatomic, readonly) FBSDKGraphRequestError errorCategory;
@property (nonatomic, readonly) NSString *recoveryActionName;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithRecoveryDescription:(NSString *)description
                         optionDescriptions:(NSArray<NSString *> *)optionDescriptions
                                   category:(FBSDKGraphRequestError)category
                         recoveryActionName:(NSString *)recoveryActionName NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
