/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKAppLinkResolverRequestBuilding.h"

NS_ASSUME_NONNULL_BEGIN

/// Class responsible for generating the appropriate FBSDKGraphRequest for a given set of urls
NS_SWIFT_NAME(AppLinkResolverRequestBuilder)
@interface FBSDKAppLinkResolverRequestBuilder : NSObject <FBSDKAppLinkResolverRequestBuilding>

@end

NS_ASSUME_NONNULL_END

#endif
