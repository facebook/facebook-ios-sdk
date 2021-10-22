/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKProductRequestFactory.h"

#import "SKProductsRequest+FBSDKProductsRequest.h"

@implementation FBSDKProductRequestFactory

- (nonnull id<FBSDKProductsRequest>)createWithProductIdentifiers:(nonnull NSSet<NSString *> *)identifiers
{
  return [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
}

@end
