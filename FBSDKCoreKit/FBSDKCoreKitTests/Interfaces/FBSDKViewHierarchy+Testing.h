/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCrashShield.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKViewHierarchy (Testing)

// This is the actual method signature for getPath:
// + (nullable NSArray<FBSDKCodelessPathComponent *> *)getPath:(NSObject *)obj;
// Since FBSDKCodelessPathComponent is internal the above method isn't exposed to Swift.
// Redefined here to allow the tests to continue to compile
+ (nullable NSArray<NSObject *> *)getPath:(NSObject *)obj;

@end

NS_ASSUME_NONNULL_END
