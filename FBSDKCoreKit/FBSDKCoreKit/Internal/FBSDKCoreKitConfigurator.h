/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKSharedDependencies.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(CoreKitConfigurator)
@interface FBSDKCoreKitConfigurator : NSObject

- (instancetype)initWithDependencies:(FBSDKSharedDependencies *)dependencies;

- (void)configureTargets;

@end

NS_ASSUME_NONNULL_END
