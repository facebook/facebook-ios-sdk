/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^FBSDKGKManagerBlock)(NSError *_Nullable error);

NS_SWIFT_NAME(GateKeeperManaging)
@protocol FBSDKGateKeeperManaging

/**
 Returns the bool value of a GateKeeper.
 */
+ (BOOL)boolForKey:(nonnull NSString *)key defaultValue:(BOOL)defaultValue;

+ (void)loadGateKeepers:(nonnull FBSDKGKManagerBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
