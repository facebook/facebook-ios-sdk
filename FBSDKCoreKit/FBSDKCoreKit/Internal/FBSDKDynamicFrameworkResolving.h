/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Used for defining behavior of types that provide classes for types that
/// exist in dynamically loaded frameworks.
@protocol FBSDKDynamicFrameworkResolving <NSObject>

- (nullable Class)safariViewControllerClass;
- (nullable Class)asIdentifierManagerClass;

@end

NS_ASSUME_NONNULL_END
