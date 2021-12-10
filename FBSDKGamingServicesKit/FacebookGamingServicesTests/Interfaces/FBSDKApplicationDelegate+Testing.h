/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKApplicationDelegate (Testing)

@property (nonnull, nonatomic) NSHashTable<id<FBSDKApplicationObserving>> *applicationObservers;

@end

NS_ASSUME_NONNULL_END
