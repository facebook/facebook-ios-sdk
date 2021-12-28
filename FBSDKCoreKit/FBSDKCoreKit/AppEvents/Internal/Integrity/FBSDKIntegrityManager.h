/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKAppEventsParameterProcessing.h"

@protocol FBSDKGateKeeperManaging;
@protocol FBSDKIntegrityProcessing;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(IntegrityManager)
@interface FBSDKIntegrityManager : NSObject <FBSDKAppEventsParameterProcessing>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                       integrityProcessor:(id<FBSDKIntegrityProcessing>)integrityProcessor;

- (void)enable;

@end

NS_ASSUME_NONNULL_END

#endif
