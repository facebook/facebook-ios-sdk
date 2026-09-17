/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@class FBSDKPaymentProductRequestor;
@class SKPaymentTransaction;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Protocol exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_PaymentProductRequestorCreating)
@protocol FBSDKPaymentProductRequestorCreating

// UNCRUSTIFY_FORMAT_OFF
- (nonnull FBSDKPaymentProductRequestor *)createRequestorWithTransaction:(SKPaymentTransaction *)transaction
NS_SWIFT_NAME(createRequestor(transaction:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#pragma clang diagnostic pop
