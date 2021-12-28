/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKPaymentObserver.h"

#import <StoreKit/StoreKit.h>

#import "FBSDKPaymentProductRequestor.h"
#import "FBSDKPaymentProductRequestorCreating.h"

@interface FBSDKPaymentObserver () <SKPaymentTransactionObserver>

@property (nonatomic, readonly) SKPaymentQueue *paymentQueue;
@property (nonatomic, readonly) id<FBSDKPaymentProductRequestorCreating> requestorFactory;
@property (nonatomic) BOOL isObservingTransactions;

@end

@implementation FBSDKPaymentObserver

- (instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue
      paymentProductRequestorFactory:(id<FBSDKPaymentProductRequestorCreating>)paymentProductRequestorFactory
{
  if ((self = [super init])) {
    _paymentQueue = paymentQueue;
    _requestorFactory = paymentProductRequestorFactory;
  }

  return self;
}

#pragma mark - Internal Methods

- (void)startObservingTransactions
{
  @synchronized(self) {
    if (!self.isObservingTransactions) {
      [self.paymentQueue addTransactionObserver:self];
      self.isObservingTransactions = YES;
    }
  }
}

- (void)stopObservingTransactions
{
  @synchronized(self) {
    if (self.isObservingTransactions) {
      [self.paymentQueue removeTransactionObserver:self];
      self.isObservingTransactions = NO;
    }
  }
}

- (void) paymentQueue:(SKPaymentQueue *)queue
  updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
  for (SKPaymentTransaction *transaction in transactions) {
    switch (transaction.transactionState) {
      case SKPaymentTransactionStatePurchasing:
      case SKPaymentTransactionStatePurchased:
      case SKPaymentTransactionStateFailed:
      case SKPaymentTransactionStateRestored:
        [self handleTransaction:transaction];
        break;
      case SKPaymentTransactionStateDeferred:
        break;
    }
  }
}

- (void)handleTransaction:(SKPaymentTransaction *)transaction
{
  FBSDKPaymentProductRequestor *productRequestor = [self.requestorFactory createRequestorWithTransaction:transaction];
  [productRequestor resolveProducts];
}

@end
