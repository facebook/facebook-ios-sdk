/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKInternalUtility+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKInternalUtility (Testing)

@property (nullable, nonatomic) id<__FBSDKLoggerCreating> loggerFactory;
@property (nullable, nonatomic) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;
@property (nonatomic) BOOL isConfigured;

+ (void)reset;

- (BOOL)_canOpenURLScheme:(nullable NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
