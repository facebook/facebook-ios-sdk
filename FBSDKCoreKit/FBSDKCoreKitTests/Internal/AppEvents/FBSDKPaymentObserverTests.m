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

#import <StoreKit/StoreKit.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "FBSDKPaymentObserver.h"

@interface FBSDKPaymentObserver ()

+ (FBSDKPaymentObserver *)singleton;
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions;
- (void)handleTransaction:(SKPaymentTransaction *)transaction;

@end

@interface FBSDKPaymentObserverTests : XCTestCase

@end

@implementation FBSDKPaymentObserverTests

- (void)testPaymentObserverAddRemove {
  FBSDKPaymentObserver *observer = [FBSDKPaymentObserver singleton];

  BOOL isObserving = [[observer valueForKeyPath:@"_observingTransactions"] boolValue];
  XCTAssertFalse(isObserving);

  [FBSDKPaymentObserver startObservingTransactions];
  isObserving = [[observer valueForKeyPath:@"_observingTransactions"] boolValue];
  XCTAssertTrue(isObserving);

  [FBSDKPaymentObserver stopObservingTransactions];
  isObserving = [[observer valueForKeyPath:@"_observingTransactions"] boolValue];
  XCTAssertFalse(isObserving);
}

- (void)testPaymenQueueUpdateTransactions
{
  id mockQueue = [OCMockObject niceMockForClass:[SKPaymentQueue class]];
  id partialMockObserver = [OCMockObject partialMockForObject:[FBSDKPaymentObserver singleton]];

  NSMutableArray<SKPaymentTransaction *> *transactions = [NSMutableArray array];
  SKPaymentTransaction *transaction = [[SKPaymentTransaction alloc] init];
  [transactions addObject:transaction];

  [[partialMockObserver expect] handleTransaction:[OCMArg any]];
  [partialMockObserver paymentQueue:mockQueue updatedTransactions:transactions];
  [partialMockObserver verify];
}


@end
