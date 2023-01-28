/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKSwizzling;
@protocol FBSDKAEMReporter;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMManager)
@interface FBSDKAEMManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)configureWithSwizzler:(nonnull Class<FBSDKSwizzling>)swizzler
                  aemReporter:(nonnull Class<FBSDKAEMReporter>)aemReporter;

- (void)enableAutoSetup;

@end

NS_ASSUME_NONNULL_END
