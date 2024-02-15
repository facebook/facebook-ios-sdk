/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKGraphRequestQueue.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGraphRequestQueue (Testing)

@property (nonatomic, strong) NSMutableArray<FBSDKGraphRequestMetadata *> *requestsQueue;
@property (nullable, nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
