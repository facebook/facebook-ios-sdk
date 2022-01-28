/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#if !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppLinkResolverRequestBuilding)
@protocol FBSDKAppLinkResolverRequestBuilding

- (id<FBSDKGraphRequest>)requestForURLs:(NSArray<NSURL *> *)urls;
- (nullable NSString *)getIdiomSpecificField;

@end

NS_ASSUME_NONNULL_END

#endif
