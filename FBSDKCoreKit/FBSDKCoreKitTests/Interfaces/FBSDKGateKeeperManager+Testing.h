/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGateKeeperManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGateKeeperManager (Testing)

@property (class, nonatomic, readonly) BOOL canLoadGateKeepers;
@property (class, nullable, nonatomic) FBSDKLogger *logger;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (class, nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nullable, nonatomic) id<FBSDKDataPersisting> store;

@property (class, nullable, nonatomic) NSDictionary<NSString *, id> *gateKeepers;
@property (class, nonatomic) BOOL requeryFinishedForAppStart;
@property (class, nullable, nonatomic) NSDate *timestamp;
@property (class, nonatomic) BOOL isLoadingGateKeepers;

// UNCRUSTIFY_FORMAT_OFF
+ (void)  configureWithSettings:(id<FBSDKSettings>)settings
            graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
  graphRequestConnectionFactory:(nonnull id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                          store:(id<FBSDKDataPersisting>)store
NS_SWIFT_NAME(configure(settings:graphRequestFactory:graphRequestConnectionFactory:store:));
// UNCRUSTIFY_FORMAT_ON

+ (id<FBSDKGraphRequest>)requestToLoadGateKeepers;

// UNCRUSTIFY_FORMAT_OFF
+ (void)processLoadRequestResponse:(nullable id)result error:(nullable NSError *)error
NS_SWIFT_NAME(parse(result:error:));
// UNCRUSTIFY_FORMAT_ON

+ (BOOL)_gateKeeperIsValid;
+ (void)reset;
+ (id<FBSDKGraphRequestFactory>)graphRequestFactory;

@end

NS_ASSUME_NONNULL_END
