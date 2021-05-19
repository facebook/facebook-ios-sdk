// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKPaymentObserver.h"

#import <StoreKit/StoreKit.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKPaymentProductRequestor.h"
#import "FBSDKPaymentProductRequestorCreating.h"
#import "FBSDKPaymentProductRequestorFactory.h"

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

+ (FBSDKPaymentObserver *)shared
{
  static FBSDKPaymentObserver *shared = nil;
  static dispatch_once_t nonce;
  dispatch_once(&nonce, ^{
    shared = [[FBSDKPaymentObserver alloc] initWithPaymentQueue:SKPaymentQueue.defaultQueue
                                 paymentProductRequestorFactory:[FBSDKPaymentProductRequestorFactory new]];
  });
  return shared;
}

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
