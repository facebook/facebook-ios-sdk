/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKCoreKit;

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKInfoDictionaryProviding;

@interface FBSDKInternalUtility (Testing)

@property (nonatomic) BOOL isConfigured;

- (void)configureWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                              loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory
                                   settings:(id<FBSDKSettings>)settings
                               errorFactory:(id<FBSDKErrorCreating>)errorFactory;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END
