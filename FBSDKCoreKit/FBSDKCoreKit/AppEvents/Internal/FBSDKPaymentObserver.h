/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol FBSDKPaymentProductRequestorCreating;

NS_ASSUME_NONNULL_BEGIN

/// Class to encapsulate implicit logging of purchase events
NS_SWIFT_NAME(PaymentObserver)
@interface FBSDKPaymentObserver : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue
      paymentProductRequestorFactory:(id<FBSDKPaymentProductRequestorCreating>)paymentProductRequestorFactory;

- (void)startObservingTransactions;
- (void)stopObservingTransactions;

@end

NS_ASSUME_NONNULL_END
