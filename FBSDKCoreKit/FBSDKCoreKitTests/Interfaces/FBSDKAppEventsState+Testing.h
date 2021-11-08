/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsState.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppEventsState (Testing)

@property (class, nullable, nonatomic) NSArray<id<FBSDKEventsProcessing>> *eventProcessors;

@end

NS_ASSUME_NONNULL_END
