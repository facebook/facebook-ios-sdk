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
 #import "FBSDKSKAdNetworkRule.h"
 #import "FBSDKTestCase.h"

@interface FBSDKSKAdNetworkRuleTests : FBSDKTestCase

@end

@implementation FBSDKSKAdNetworkRuleTests

- (void)testInit
{
  // Valid cases
  NSDictionary<NSString *, id> *validData = @{
    @"conversion_value" : @(2),
    @"events" : @[
      @{
        @"event_name" : @"fb_mobile_purchase",
      },
      @{
        @"event_name" : @"Donate",
      }
    ],
  };
  FBSDKSKAdNetworkRule *rule = [[FBSDKSKAdNetworkRule alloc] initWithJSON:validData];
  XCTAssertEqual(2, rule.conversionValue);
  XCTAssertEqual(2, rule.events.count);
  FBSDKSKAdNetworkEvent *event1 = [FBSDKTypeUtility array:rule.events objectAtIndex:0];
  FBSDKSKAdNetworkEvent *event2 = [FBSDKTypeUtility array:rule.events objectAtIndex:1];
  XCTAssertTrue([event1.eventName isEqualToString:@"fb_mobile_purchase"]);
  XCTAssertNil(event1.values);
  XCTAssertTrue([event2.eventName isEqualToString:@"Donate"]);
  XCTAssertNil(event2.values);

  validData = @{
    @"conversion_value" : @(2),
    @"events" : @[
      @{
        @"event_name" : @"fb_mobile_purchase",
        @"values" : @[
          @{
            @"currency" : @"USD",
            @"amount" : @(100)
          }
        ]
      }
    ],
  };
  rule = [[FBSDKSKAdNetworkRule alloc] initWithJSON:validData];
  XCTAssertEqual(2, rule.conversionValue);
  XCTAssertEqual(1, rule.events.count);
  XCTAssertEqual(1, rule.events.count);
  event1 = [FBSDKTypeUtility array:rule.events objectAtIndex:0];
  XCTAssertTrue([event1.eventName isEqualToString:@"fb_mobile_purchase"]);
  XCTAssertTrue([event1.values isEqualToDictionary:@{@"USD" : @(100)}]);

  // Invalid cases
  id invalidData = nil;
  XCTAssertNil([[FBSDKSKAdNetworkRule alloc] initWithJSON:invalidData]);
  invalidData = @[];
  XCTAssertNil([[FBSDKSKAdNetworkRule alloc] initWithJSON:invalidData]);
  invalidData = @{
    @"conversion_value" : @(2),
  };
  XCTAssertNil([[FBSDKSKAdNetworkRule alloc] initWithJSON:invalidData]);
  invalidData = @{
    @"events" : @[
      @{
        @"event_name" : @"fb_mobile_purchase",
        @"values" : @[
          @{
            @"currency" : @"USD",
            @"amount" : @(100)
          }
        ]
      }
    ],
  };
  XCTAssertNil([[FBSDKSKAdNetworkRule alloc] initWithJSON:invalidData]);
  invalidData = @{
    @"conversion_value" : @(2),
    @"events" : @[
      @{
        @"event_name" : @"fb_mobile_purchase",
        @"values" : @[
          @{
            @"currency" : @(100),
            @"amount" : @"USD"
          }
        ]
      }
    ],
  };
  XCTAssertNil([[FBSDKSKAdNetworkRule alloc] initWithJSON:invalidData]);
}

- (void)testRuleMatch
{
  NSDictionary<NSString *, id> *ruleData = @{
    @"conversion_value" : @(2),
    @"events" : @[
      @{
        @"event_name" : @"fb_skadnetwork_test1",
      },
      @{
        @"event_name" : @"fb_mobile_purchase",
        @"values" : @[
          @{
            @"currency" : @"USD",
            @"amount" : @(100)
          }
        ]
      }
    ],
  };
  FBSDKSKAdNetworkRule *rule = [[FBSDKSKAdNetworkRule alloc] initWithJSON:ruleData];

  NSSet<NSString *> *matchedEventSet = [NSSet setWithArray:@[@"fb_mobile_purchase", @"fb_skadnetwork_test1", @"fb_adnetwork_test2"]];
  NSSet<NSString *> *unmatchedEventSet = [NSSet setWithArray:@[@"fb_mobile_purchase", @"fb_skadnetwork_test2"]];
  XCTAssertTrue(
    [rule isMatchedWithRecordedEvents:matchedEventSet recordedValues:@{
       @"fb_mobile_purchase" : @{@"USD" : @(1000)}
     }]
  );
  XCTAssertFalse([rule isMatchedWithRecordedEvents:[NSSet new] recordedValues:[NSDictionary new]]);
  XCTAssertFalse([rule isMatchedWithRecordedEvents:matchedEventSet recordedValues:[NSDictionary new]]);
  XCTAssertFalse(
    [rule isMatchedWithRecordedEvents:matchedEventSet recordedValues:@{
       @"fb_mobile_purchase" : @{@"USD" : @(50)}
     }]
  );
  XCTAssertFalse(
    [rule isMatchedWithRecordedEvents:matchedEventSet recordedValues:@{
       @"fb_mobile_purchase" : @{@"JPY" : @(1000)}
     }]
  );
  XCTAssertFalse(
    [rule isMatchedWithRecordedEvents:unmatchedEventSet recordedValues:@{
       @"fb_mobile_purchase" : @{@"USD" : @(1000)}
     }]
  );
}

@end

#endif
