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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#if !TARGET_OS_TV

 #import "FBSDKCoreKit+Internal.h"
 #import "FBSDKSKAdNetworkEvent.h"
 #import "FBSDKTestCase.h"

@interface FBSDKSKAdNetworkEventTests : FBSDKTestCase

@end

@implementation FBSDKSKAdNetworkEventTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testInit
{
  // Valid cases
  FBSDKSKAdNetworkEvent *event = [[FBSDKSKAdNetworkEvent alloc] initWithJSON:@{@"event_name" : @"fb_mobile_purchase"}];
  XCTAssertTrue([event.eventName isEqualToString:@"fb_mobile_purchase"]);
  XCTAssertNil(event.values);
  event = [[FBSDKSKAdNetworkEvent alloc] initWithJSON:@{
             @"event_name" : @"fb_mobile_purchase",
             @"values" : @[
               @{
                 @"currency" : @"usd",
                 @"amount" : @(100)
               },
               @{
                 @"currency" : @"JPY",
                 @"amount" : @(1000)
               }
             ]
           }];
  XCTAssertTrue([event.eventName isEqualToString:@"fb_mobile_purchase"]);
  NSDictionary<NSString *, NSNumber *> *expectedValues = @{@"USD" : @(100), @"JPY" : @(1000)};
  XCTAssertTrue([event.values isEqualToDictionary:expectedValues]);

  // Invalid cases
  id invalidData = nil;
  XCTAssertNil([[FBSDKSKAdNetworkEvent alloc] initWithJSON:invalidData]);
  invalidData = @[];
  XCTAssertNil([[FBSDKSKAdNetworkEvent alloc] initWithJSON:invalidData]);
  invalidData = @{
    @"values" : @[
      @{
        @"currency" : @"usd",
        @"amount" : @(100)
      },
      @{
        @"currency" : @"JPY",
        @"amount" : @(1000)
      }
    ]
  };
  XCTAssertNil([[FBSDKSKAdNetworkEvent alloc] initWithJSON:invalidData]);
  invalidData = @{
    @"event_name" : @"fb_mobile_purchase",
    @"values" : @[
      @{
        @"currency" : @(100),
        @"amount" : @"usd"
      },
      @{
        @"currency" : @(1000),
        @"amount" : @"jpy"
      }
    ]
  };
  XCTAssertNil([[FBSDKSKAdNetworkEvent alloc] initWithJSON:invalidData]);
}

@end

#endif
