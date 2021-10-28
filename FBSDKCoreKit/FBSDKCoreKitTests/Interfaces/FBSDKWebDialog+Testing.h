/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKWebDialog+Internal.h"

@protocol FBSDKWindowFinding;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKWebDialog (Testing)

@property (nonatomic, strong) id<FBSDKWindowFinding> windowFinder;

- (NSURL *)_generateURL:(NSError **)errorRef;

@end

NS_ASSUME_NONNULL_END
