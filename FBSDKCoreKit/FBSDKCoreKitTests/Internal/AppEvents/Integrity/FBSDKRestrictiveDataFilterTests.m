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

#import <OCMock/OCMock.h>

#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKRestrictiveDataFilterManager.h"

@interface FBSDKRestrictiveDataFilterManager ()

+ (void)updateFilters:(nullable NSDictionary<NSString *, id> *)restrictiveParams;
+ (NSString *)getMatchedDataTypeWithEventName:(NSString *)eventName
                                     paramKey:(NSString *)paramKey;

@end

@interface FBSDKRestrictiveDataFilterTests : XCTestCase
@end

@implementation FBSDKRestrictiveDataFilterTests

- (void)setUp
{
  [super setUp];

  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary: @{
    @"test_event_name" : @{
        @"restrictive_param" : @{
            @"first name" : @"6",
            @"last name" : @"7"
        }
    },
    @"restrictive_event_name" : @{
        @"restrictive_param" : @{
            @"dob" : @4
        }
    }
  }];

  id mockServerConfiguration = OCMClassMock([FBSDKServerConfiguration class]);
  OCMStub([mockServerConfiguration restrictiveParams]).andReturn(params);
  id mockServerConfigurationManager = OCMClassMock([FBSDKServerConfigurationManager class]);
  OCMStub([mockServerConfigurationManager cachedServerConfiguration]).andReturn(mockServerConfiguration);

  [FBSDKRestrictiveDataFilterManager enable];
}

- (void)testFilterByParams
{
  NSString *testEventName = @"restrictive_event_name";
  id mockAppStates = [OCMockObject niceMockForClass:[FBSDKAppEventsState class]];
  OCMStub([mockAppStates alloc]).andReturn(mockAppStates);
  OCMStub([mockAppStates initWithToken:[OCMArg any] appID:[OCMArg any]]).andReturn(mockAppStates);

  // filtered by param key
  [[mockAppStates expect] addEvent:[OCMArg checkWithBlock:^(id value){
    XCTAssertEqualObjects(value[@"_eventName"], testEventName);
    XCTAssertNil(value[@"dob"]);
    XCTAssertEqualObjects(value[@"_restrictedParams"], @"{\"dob\":\"4\"}");
    return YES;
  }] isImplicit:NO];
  [FBSDKAppEvents logEvent:testEventName parameters:@{@"dob": @"06-29-2019"}];
  [mockAppStates verify];

  // should not be filtered
  [[mockAppStates expect] addEvent:[OCMArg checkWithBlock:^(id value){
    XCTAssertEqualObjects(value[@"_eventName"], testEventName);
    XCTAssertEqualObjects(value[@"test_key"], @66666);
    XCTAssertNil(value[@"_restrictedParams"]);
    return YES;
  }] isImplicit:NO];
  [FBSDKAppEvents logEvent:testEventName parameters:@{@"test_key": @66666}];
  [mockAppStates verify];
}

- (void)testGetMatchedDataTypeByParam
{
  NSString *testEventName = @"test_event_name";
  NSString *type1 = [FBSDKRestrictiveDataFilterManager getMatchedDataTypeWithEventName:testEventName paramKey:@"first name"];
  XCTAssertEqualObjects(type1, @"6");

  NSString *type2= [FBSDKRestrictiveDataFilterManager getMatchedDataTypeWithEventName:testEventName paramKey:@"reservation number"];
  XCTAssertNil(type2);
}

- (void)testProcessEventCanHandleAnEmptyArray
{
  NSMutableArray *a = nil;
  XCTAssertNoThrow([FBSDKRestrictiveDataFilterManager processEvents:a]);
}

- (void)testProcessEventCanHandleMissingKeys
{
  NSDictionary<NSString *, NSDictionary<NSString *, id> *> *event = @{
    @"some_event": @{}
  };
  NSMutableArray *eventArray = [[NSMutableArray alloc] initWithObjects:event, nil];

  XCTAssertNoThrow([FBSDKRestrictiveDataFilterManager processEvents:eventArray],
                   "Data filter manager should be able to process events with missing keys");
}

- (void)testProcessEventDoesntReplaceEventNameIfNotRestricted
{
  NSDictionary<NSString *, NSDictionary<NSString *, id> *> *event = @{
    @"event": @{
        @"_eventName": [NSNull null],
    }
  };
  NSMutableArray *eventArray = [[NSMutableArray alloc] initWithObjects:event, nil];

  [FBSDKRestrictiveDataFilterManager processEvents:eventArray];

  XCTAssertEqual(event[@"event"][@"_eventName"], [NSNull null],
                 "Non-restricted event names should not be replaced");
}

@end
