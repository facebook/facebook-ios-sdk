/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKGraphRequestQueue.h>

@protocol FBSDKSettings;
@protocol FBSDKErrorCreating;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGraphRequestQueue (Testing)

@property (nonatomic, strong) NSMutableArray<FBSDKGraphRequestMetadata *> *requestsQueue;
@property (nullable, nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nullable, nonatomic, weak) id<FBSDKSettings> settings;
@property (nonatomic, strong) id<FBSDKErrorCreating> errorFactory;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
