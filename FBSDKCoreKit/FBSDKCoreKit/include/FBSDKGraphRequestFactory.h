/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestFactoryProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKGraphRequestFactory;

/**
 Internal type not intended for use outside of the SDKs.

 A factory for providing objects that conform to `GraphRequest`
*/
NS_SWIFT_NAME(GraphRequestFactory)
@interface FBSDKGraphRequestFactory : NSObject <FBSDKGraphRequestFactory>
@end

NS_ASSUME_NONNULL_END
