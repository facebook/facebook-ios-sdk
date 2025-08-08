/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "SKProductsRequest+FBSDKProductsRequest.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation FBSDKProductRequestFactory

- (nonnull id<FBSDKProductsRequest>)createWithProductIdentifiers:(nonnull NSSet<NSString *> *)identifiers
{
  return [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
}

#pragma clang diagnostic pop

@end
