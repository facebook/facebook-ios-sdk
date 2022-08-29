/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKAppLinkResolverRequestBuilding.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Protocol exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 
 Class responsible for generating the appropriate FBSDKGraphRequest for a given set of urls
 */
NS_SWIFT_NAME(_AppLinkResolverRequestBuilder)
@interface FBSDKAppLinkResolverRequestBuilder : NSObject <FBSDKAppLinkResolverRequestBuilding>

@end

NS_ASSUME_NONNULL_END

#endif
