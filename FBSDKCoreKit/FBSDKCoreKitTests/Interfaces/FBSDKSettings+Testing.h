/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSettings (Testing)

@property (class, nonatomic, nullable, readonly) id<FBSDKDataPersisting> store;
@property (class, nonatomic, nullable, readonly) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (class, nonatomic, nullable) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (class, nonatomic, nullable) id<FBSDKEventLogging> eventLogger;

+ (void)configureWithStore:(id<FBSDKDataPersisting>)store
appEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)provider
    infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
               eventLogger:(id<FBSDKEventLogging>)eventLogger
NS_SWIFT_NAME(configure(store:appEventsConfigurationProvider:infoDictionaryProvider:eventLogger:));

- (void)setDataProcessingOptions:(nullable NSArray<NSString *> *)options
                         country:(int)country
                           state:(int)state;

- (void)reset;

- (void)enableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior;

- (void)disableLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior;

- (void)setLoggingBehaviors:(NSSet<FBSDKLoggingBehavior> *)loggingBehaviors;

@end

NS_ASSUME_NONNULL_END
