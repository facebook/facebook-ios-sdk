/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsATEPublisher.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppEventsATEPublisher (Testing)

@property (nonatomic, strong) id<FBSDKDataPersisting> store;
@property (nonatomic) BOOL isProcessing;

@end

NS_ASSUME_NONNULL_END
