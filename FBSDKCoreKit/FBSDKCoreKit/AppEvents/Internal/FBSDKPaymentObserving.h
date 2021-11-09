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

// These methods need Swift name overrides since they otherwise get changed to
// `startTransactions` and `stopTransactions` otherwise.
- (void)startObservingTransactions NS_SWIFT_NAME(startObservingTransactions());
- (void)stopObservingTransactions NS_SWIFT_NAME(stopObservingTransactions());

@end

NS_ASSUME_NONNULL_END
