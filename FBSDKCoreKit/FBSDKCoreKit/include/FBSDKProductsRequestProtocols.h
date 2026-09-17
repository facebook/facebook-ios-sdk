/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@protocol SKProductsRequestDelegate;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE

 An abstraction for an `SKProductsRequest` instance
 */
NS_SWIFT_NAME(_ProductsRequest)
@protocol FBSDKProductsRequest

@property (nullable, nonatomic, weak) id<SKProductsRequestDelegate> delegate;

- (void)cancel;
- (void)start;

@end

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE

 An abstraction for any object that can create a `ProductsRequest`
 */
NS_SWIFT_NAME(_ProductsRequestCreating)
@protocol FBSDKProductsRequestCreating

- (id<FBSDKProductsRequest>)createWithProductIdentifiers:(NSSet<NSString *> *)identifiers;

@end

NS_ASSUME_NONNULL_END

#pragma clang diagnostic pop
