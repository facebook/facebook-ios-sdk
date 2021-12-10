/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestConnectionFactoryProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type not intended for use outside of the SDKs.

 A factory for providing objects that conform to `GraphRequestConnecting`.
 */
NS_SWIFT_NAME(GraphRequestConnectionFactory)
@interface FBSDKGraphRequestConnectionFactory : NSObject <FBSDKGraphRequestConnectionFactory>
@end

NS_ASSUME_NONNULL_END
