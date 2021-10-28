/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGraphRequest (Testing)

@property (nullable, nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nullable, nonatomic, strong) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic, readonly) Class<FBSDKTokenStringProviding> currentAccessTokenStringProvider;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END
