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

#import <XCTest/XCTest.h>

#import "FBSDKInternalUtility.h"
#import "FBSDKRestrictiveData.h"

@interface FBSDKRestrictiveDataTests : XCTestCase

@end

@implementation FBSDKRestrictiveDataTests
{
  NSDictionary<NSString *, NSString *> *_restrictiveParam1;
  NSDictionary<NSString *, NSString *> *_restrictiveParam2;
  NSArray<NSString *> *_deprecatedParam1;
  NSArray<NSString *> *_deprecatedParam2;
}

- (void)setUp
{
  _restrictiveParam1 = @{@"restrictive_key_1" : @"restrictive_value_1",
                         @"restrictive_key_2" : @"restrictive_value_2"};
  _restrictiveParam2 = @{@"restrictive_key_1" : @"restrictive_value_3",
                         @"restrictive_key_2" : @"restrictive_value_4"};
  _deprecatedParam1 = @[@"deprecated_value_1", @"deprecated_value_2"];
  _deprecatedParam2 = @[@"deprecated_value_3", @"deprecated_value_4"];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testGeneralServerResponse
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @{
      @"restrictive_param" : _restrictiveParam1,
      @"deprecated_param" : _deprecatedParam1,
      @"is_deprecated_event" : @true,
    },
    @"test_event_name_2" : @{
      @"restrictive_param" : _restrictiveParam2,
      @"deprecated_param" : _deprecatedParam2,
      @"is_deprecated_event" : @false,
    }
  };
  NSMutableArray<FBSDKRestrictiveData *> *restrictiveData = [NSMutableArray new];
  for (NSString *eventName in serverResponse) {
    [FBSDKTypeUtility array:restrictiveData addObject:[[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]]];
  }
  XCTAssertEqual(2, restrictiveData.count, "The expected array length should be equal to the acutal array length.");
  FBSDKRestrictiveData *eventData1 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:0];
  XCTAssertEqualObjects(@"test_event_name_1", eventData1.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam1, eventData1.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam1, eventData1.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertTrue(eventData1.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
  FBSDKRestrictiveData *eventData2 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:1];
  XCTAssertEqualObjects(@"test_event_name_2", eventData2.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam2, eventData2.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam2, eventData2.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertFalse(eventData2.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
}

- (void)testServerResponseWithMismatchType
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @[@"value_1", @"value_2"],
    @"test_event_name_2" : @[@"value_3", @"value_4"]
  };
  for (NSString *eventName in serverResponse) {
    FBSDKRestrictiveData *restrictiveData = [[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]];
    XCTAssertNil(restrictiveData);
  }
}

- (void)testServerResponseWithExtraFields
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @{
      @"restrictive_param" : _restrictiveParam1,
      @"deprecated_param" : _deprecatedParam1,
      @"new_filed" : @"new_filed_string_1",
      @"is_deprecated_event" : @true,
    },
    @"test_event_name_2" : @{
      @"restrictive_param" : _restrictiveParam2,
      @"deprecated_param" : _deprecatedParam2,
      @"new_filed" : @"new_filed_string_2",
      @"is_deprecated_event" : @false,
    }
  };
  NSMutableArray<FBSDKRestrictiveData *> *restrictiveData = [NSMutableArray new];
  for (NSString *eventName in serverResponse) {
    [FBSDKTypeUtility array:restrictiveData addObject:[[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]]];
  }
  XCTAssertEqual(2, restrictiveData.count, "The expected array length should be equal to the acutal array length.");
  FBSDKRestrictiveData *eventData1 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:0];
  XCTAssertEqualObjects(@"test_event_name_1", eventData1.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam1, eventData1.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam1, eventData1.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertTrue(eventData1.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
  FBSDKRestrictiveData *eventData2 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:1];
  XCTAssertEqualObjects(@"test_event_name_2", eventData2.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam2, eventData2.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam2, eventData2.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertFalse(eventData2.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
}

- (void)testServerResponseWithMissingRestrictiveParam
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @{
      @"deprecated_param" : _deprecatedParam1,
      @"is_deprecated_event" : @true,
    },
    @"test_event_name_2" : @{
      @"deprecated_param" : _deprecatedParam2,
      @"is_deprecated_event" : @false,
    }
  };
  NSMutableArray<FBSDKRestrictiveData *> *restrictiveData = [NSMutableArray new];
  for (NSString *eventName in serverResponse) {
    [FBSDKTypeUtility array:restrictiveData addObject:[[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]]];
  }
  XCTAssertEqual(2, restrictiveData.count, "The expected array length should be equal to the acutal array length.");
  FBSDKRestrictiveData *eventData1 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:0];
  XCTAssertEqualObjects(@"test_event_name_1", eventData1.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertNil(eventData1.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam1, eventData1.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertTrue(eventData1.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
  FBSDKRestrictiveData *eventData2 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:1];
  XCTAssertEqualObjects(@"test_event_name_2", eventData2.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertNil(eventData2.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam2, eventData2.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertFalse(eventData2.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
}

- (void)testServerResponseWithMissingDeprecatedParam
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @{
      @"restrictive_param" : _restrictiveParam1,
      @"is_deprecated_event" : @true,
    },
    @"test_event_name_2" : @{
      @"restrictive_param" : _restrictiveParam2,
      @"is_deprecated_event" : @false,
    }
  };
  NSMutableArray<FBSDKRestrictiveData *> *restrictiveData = [NSMutableArray new];
  for (NSString *eventName in serverResponse) {
    [FBSDKTypeUtility array:restrictiveData addObject:[[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]]];
  }
  XCTAssertEqual(2, restrictiveData.count, "The expected array length should be equal to the acutal array length.");
  FBSDKRestrictiveData *eventData1 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:0];
  XCTAssertEqualObjects(@"test_event_name_1", eventData1.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam1, eventData1.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertNil(eventData1.deprecatedParams, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
  XCTAssertTrue(eventData1.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  FBSDKRestrictiveData *eventData2 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:1];
  XCTAssertEqualObjects(@"test_event_name_2", eventData2.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam2, eventData2.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertNil(eventData2.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertFalse(eventData2.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
}

- (void)testServerResponseWithMissingIsDeprecatedEvent
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @{
      @"restrictive_param" : _restrictiveParam1,
      @"deprecated_param" : _deprecatedParam1,
    },
    @"test_event_name_2" : @{
      @"restrictive_param" : _restrictiveParam2,
      @"deprecated_param" : _deprecatedParam2,
    }
  };
  NSMutableArray<FBSDKRestrictiveData *> *restrictiveData = [NSMutableArray new];
  for (NSString *eventName in serverResponse) {
    [FBSDKTypeUtility array:restrictiveData addObject:[[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]]];
  }
  XCTAssertEqual(2, restrictiveData.count, "The expected array length should be equal to the acutal array length.");
  FBSDKRestrictiveData *eventData1 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:0];
  XCTAssertEqualObjects(@"test_event_name_1", eventData1.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam1, eventData1.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam1, eventData1.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertFalse(eventData1.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
  FBSDKRestrictiveData *eventData2 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:1];
  XCTAssertEqualObjects(@"test_event_name_2", eventData2.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam2, eventData2.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(_deprecatedParam2, eventData2.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertFalse(eventData2.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
}

- (void)testServerResponseWithEmptyRestrictiveParam
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @{
      @"restrictive_param" : @{},
      @"deprecated_param" : _deprecatedParam1,
      @"is_deprecated_event" : @true,
    },
    @"test_event_name_2" : @{
      @"restrictive_param" : @{},
      @"deprecated_param" : _deprecatedParam2,
      @"is_deprecated_event" : @false,
    }
  };
  NSMutableArray<FBSDKRestrictiveData *> *restrictiveData = [NSMutableArray new];
  for (NSString *eventName in serverResponse) {
    [FBSDKTypeUtility array:restrictiveData addObject:[[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]]];
  }
  XCTAssertEqual(2, restrictiveData.count, "The expected array length should be equal to the acutal array length.");
  FBSDKRestrictiveData *eventData1 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:0];
  XCTAssertEqualObjects(@"test_event_name_1", eventData1.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(@{}, eventData1.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be empty when the restrictive_param field of server response is empty.");
  XCTAssertEqualObjects(_deprecatedParam1, eventData1.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertTrue(eventData1.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
  FBSDKRestrictiveData *eventData2 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:1];
  XCTAssertEqualObjects(@"test_event_name_2", eventData2.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(@{}, eventData2.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be empty when the restrictive_param field of server response is empty.");
  XCTAssertEqualObjects(_deprecatedParam2, eventData2.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field.");
  XCTAssertFalse(eventData2.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
}

- (void)testServerResponseWithEmptyDeprecatedParam
{
  NSDictionary<NSString *, id> *serverResponse = @{
    @"test_event_name_1" : @{
      @"restrictive_param" : _restrictiveParam1,
      @"deprecated_param" : @[],
      @"is_deprecated_event" : @true,
    },
    @"test_event_name_2" : @{
      @"restrictive_param" : _restrictiveParam2,
      @"deprecated_param" : @[],
      @"is_deprecated_event" : @false,
    }
  };
  NSMutableArray<FBSDKRestrictiveData *> *restrictiveData = [NSMutableArray new];
  for (NSString *eventName in serverResponse) {
    [FBSDKTypeUtility array:restrictiveData addObject:[[FBSDKRestrictiveData alloc] initWithEventName:eventName params:serverResponse[eventName]]];
  }
  XCTAssertEqual(2, restrictiveData.count, "The expected array length should be equal to the acutal array length.");
  FBSDKRestrictiveData *eventData1 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:0];
  XCTAssertEqualObjects(@"test_event_name_1", eventData1.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam1, eventData1.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(@[], eventData1.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be empty when the deprecated_param field of server response is empty.");
  XCTAssertTrue(eventData1.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
  FBSDKRestrictiveData *eventData2 = [FBSDKTypeUtility array:restrictiveData objectAtIndex:1];
  XCTAssertEqualObjects(@"test_event_name_2", eventData2.eventName, "The FBSDKRestrictiveData's eventName property should be equal to the actual event name.");
  XCTAssertEqualObjects(_restrictiveParam2, eventData2.restrictiveParams, "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field.");
  XCTAssertEqualObjects(@[], eventData2.deprecatedParams, "The FBSDKRestrictiveData's deprecatedParams property should be empty when the deprecated_param field of server response is empty.");
  XCTAssertFalse(eventData2.deprecatedEvent, "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field.");
}

@end
