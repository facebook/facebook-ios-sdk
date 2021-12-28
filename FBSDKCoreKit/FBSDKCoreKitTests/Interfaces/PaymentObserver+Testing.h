/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKPaymentObserver.h"
#import "FBSDKPaymentProductRequestorCreating.h"

@class SKPaymentQueue;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKPaymentObserver (Testing)

@property (nonatomic, readonly) SKPaymentQueue *paymentQueue;
@property (nonatomic, readonly) id<FBSDKPaymentProductRequestorCreating> requestorFactory;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue
      paymentProductRequestorFactory:(id<FBSDKPaymentProductRequestorCreating>)paymentProductRequestorFactory
NS_SWIFT_NAME(init(paymentQueue:paymentProductRequestorFactory:));
// UNCRUSTIFY_FORMAT_ON

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;

@end

NS_ASSUME_NONNULL_END
