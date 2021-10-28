/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKInternalUtility (Testing)

@property (class, nonnull, nonatomic) Class<FBSDKLogging> loggerType;
@property (nullable, nonatomic) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nonatomic) BOOL isConfigured;

+ (void)configureWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider;
+ (void)reset;

- (BOOL)_canOpenURLScheme:(nullable NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
