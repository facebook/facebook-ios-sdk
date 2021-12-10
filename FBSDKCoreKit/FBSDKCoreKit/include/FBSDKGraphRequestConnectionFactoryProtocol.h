/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKGraphRequestConnecting;

/// Describes anything that can provide instances of `FBSDKGraphRequestConnecting`
NS_SWIFT_NAME(GraphRequestConnectionFactoryProtocol)
@protocol FBSDKGraphRequestConnectionFactory

- (id<FBSDKGraphRequestConnecting>)createGraphRequestConnection;

@end

NS_ASSUME_NONNULL_END
