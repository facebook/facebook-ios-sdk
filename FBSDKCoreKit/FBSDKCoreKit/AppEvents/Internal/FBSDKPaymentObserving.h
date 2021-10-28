/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Protocol of the class to encapsulate implicit logging of purchase events
NS_SWIFT_NAME(PaymentObserving)
@protocol FBSDKPaymentObserving

- (void)startObservingTransactions;
- (void)stopObservingTransactions;

@end

NS_ASSUME_NONNULL_END
