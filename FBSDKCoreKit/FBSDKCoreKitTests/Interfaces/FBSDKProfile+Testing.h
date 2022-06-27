/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKProfile+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKProfile (Testing)

@property (class, nullable, nonatomic) id<FBSDKDataPersisting> dataStore;
@property (class, nullable, nonatomic) Class<FBSDKAccessTokenProviding> accessTokenProvider;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKNotificationPosting, FBSDKNotificationDelivering> notificationCenter;
@property (class, nullable, nonatomic) id<FBSDKURLHosting> urlHoster;

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification;

+ (void)reset;

+ (void)resetCurrentProfileCache;

+ (NSString *)graphPathForToken:(FBSDKAccessToken *)token;

// UNCRUSTIFY_FORMAT_OFF
+ (void)loadProfileWithToken:(nullable FBSDKAccessToken *)token
                graphRequest:(id<FBSDKGraphRequest>)request
                  completion:(nullable FBSDKProfileBlock)completion
NS_SWIFT_NAME(load(token:request:completion:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
