/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <StoreKit/StoreKit.h>

#import "FBSDKProductsRequestProtocols.h"

NS_ASSUME_NONNULL_BEGIN

/// Default conformance to the `ProductRequest` protocol
@interface SKProductsRequest () <FBSDKProductsRequest>
@end

NS_ASSUME_NONNULL_END
