/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGateKeeperManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGateKeeperManager (Testing)

@property (class, nonatomic, readonly) BOOL canLoadGateKeepers;
@property (class, nonatomic, nullable) FBSDKLogger *logger;
@property (class, nonatomic, nullable) id<FBSDKSettings> settings;
@property (class, nonatomic, nullable) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (class, nonatomic, nullable) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nonatomic, nullable) id<FBSDKDataPersisting> store;

@property (class, nonatomic, nullable) NSDictionary<NSString *, id> *gateKeepers;
@property (class, nonatomic) BOOL requeryFinishedForAppStart;
@property (class, nonatomic, nullable) NSDate *timestamp;
@property (class, nonatomic) BOOL isLoadingGateKeepers;

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
           graphRequestConnectionFactory:(nonnull id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                        store:(id<FBSDKDataPersisting>)store
NS_SWIFT_NAME(configure(settings:graphRequestFactory:graphRequestConnectionFactory:store:));
+ (id<FBSDKGraphRequest>)requestToLoadGateKeepers;
+ (void)processLoadRequestResponse:(nullable id)result error:(nullable NSError *)error
NS_SWIFT_NAME(parse(result:error:));
+ (BOOL)_gateKeeperIsValid;
+ (void)reset;
+ (id<FBSDKGraphRequestFactory>)graphRequestFactory;

@end

NS_ASSUME_NONNULL_END
