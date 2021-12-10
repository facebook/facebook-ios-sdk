/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@protocol SKProductsRequestDelegate;

NS_ASSUME_NONNULL_BEGIN

/// An abstraction for an `SKProductsRequest` instance
NS_SWIFT_NAME(ProductsRequest)
@protocol FBSDKProductsRequest

@property (nullable, nonatomic, weak) id<SKProductsRequestDelegate> delegate;

- (void)cancel;
- (void)start;

@end

/// An abstraction for any object that can create a `ProductsRequest`
NS_SWIFT_NAME(ProductsRequestCreating)
@protocol FBSDKProductsRequestCreating

- (id<FBSDKProductsRequest>)createWithProductIdentifiers:(NSSet<NSString *> *)identifiers;

@end

NS_ASSUME_NONNULL_END
