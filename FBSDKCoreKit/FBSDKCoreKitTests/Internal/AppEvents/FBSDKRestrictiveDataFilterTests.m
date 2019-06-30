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
#import "FBSDKRestrictiveDataFilterManager.h"

@interface FBSDKRestrictiveDataFilterManager ()

+ (BOOL)isMatchedWithPattern:(NSString *)pattern
                        text:(NSString *)text;

@end

@interface FBSDKRestrictiveDataFilterTests : XCTestCase

@end

@implementation FBSDKRestrictiveDataFilterTests

- (void)setUp
{
  [super setUp];

}

- (void)tearDown
{
  [super tearDown];
}

- (void)testIsMatchedWithPatternPhoneNumber
{
  NSString *pattern = @"^phone$|phone number|cell phone|mobile phone|^mobile$";
  NSString *text1 = @"phone";
  NSString *text2 = @"phone number";
  NSString *text3 = @"cell phone";
  NSString *text4 = @"mobile phone";
  NSString *text5 = @"mobile";

  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text1]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text2]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text3]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text4]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text5]);

  NSString *text6 = @"cell_phone";
  NSString *text7 = @"phone_number";

  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text6]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text7]);
}

- (void)testIsMatchedWithPatternSSN
{
  NSString *pattern = @"^ssn$|social security number|social security";
  NSString *text1 = @"ssn";
  NSString *text2 = @"SSN";
  NSString *text3 = @"social security number";
  NSString *text4 = @"social security";

  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text1]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text2]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text3]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text4]);

  NSString *text5 = @"ssn1";
  NSString *text6 = @"social";

  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text5]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text6]);
}

- (void)testIsMatchedWithPatternPassword
{
  NSString *pattern = @"password|passcode|passId";
  NSString *text1 = @"password";
  NSString *text2 = @"passcode";
  NSString *text3 = @"passID";

  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text1]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text2]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text3]);

  NSString *text4 = @"ssn";
  NSString *text5 = @"social";

  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text4]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text5]);
}

- (void)testIsMatchedWithPatternFirstName
{
  NSString *pattern = @"firstname|first_name|first name";
  NSString *text1 = @"firstname";
  NSString *text2 = @"first_name";
  NSString *text3 = @"first name";

  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text1]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text2]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text3]);

  NSString *text4 = @"last name";
  NSString *text5 = @"middle name";

  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text4]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text5]);
}

- (void)testIsMatchedWithPatternLastName
{
  NSString *pattern = @"lastname|last_name|last name";
  NSString *text1 = @"lastname";
  NSString *text2 = @"last_name";
  NSString *text3 = @"last name";

  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text1]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text2]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text3]);

  NSString *text4 = @"first name";
  NSString *text5 = @"middle name";

  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text4]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text5]);
}

- (void)testIsMatchedWithPatternDateOfBirth
{
  NSString *pattern = @"date_of_birth|<dob>|dob>|birthdate|userbirthday|dateofbirth|date of birth|<dob_|dobd|dobm|doby";
  NSString *text1 = @"date_of_birth";
  NSString *text2 = @"<dob>";
  NSString *text3 = @"birthdate";
  NSString *text4 = @"userbirthday";
  NSString *text5 = @"dateofbirth";
  NSString *text6 = @"date of birth";

  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text1]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text2]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text3]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text4]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text5]);
  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text6]);

  NSString *text7 = @"dob_";
  NSString *text8 = @"date";
  NSString *text9 = @"bday";

  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text7]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text8]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isMatchedWithPattern:pattern text:text9]);
}

- (void)testGetMatchedDataTypeByRule
{
  NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *rules = [NSMutableArray array];
  NSString *eventName = @"manual_initiated_checkout";

  NSMutableDictionary<NSString *, NSString *> *rule1 =  [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                                         @"key_regex" : @"^phone$|phone number|cell phone|mobile phone|^mobile$",
                                                                                                         @"value_negative_regex" : @"required|true|false|yes|y|n|off|on",
                                                                                                         @"type" : @"type",
                                                                                                         }];

  [rules addObject:rule1];
  [FBSDKRestrictiveDataFilterManager updateFilters:rules restrictiveParams:nil];

  NSString *type1 = [FBSDKRestrictiveDataFilterManager getMatchedDataTypeWithEventName:eventName paramKey:@"phone number" paramValue:@""];
  XCTAssertEqualObjects(type1, @"type");

  NSString *type2 = [FBSDKRestrictiveDataFilterManager getMatchedDataTypeWithEventName:eventName paramKey:@"cell phone" paramValue:@"required"];
  XCTAssertNil(type2);
}

- (void)testFilterByRules
{
  NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *rules = [NSMutableArray array];

  NSMutableDictionary<NSString *, NSString *> *rule1 =  [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                                         @"value_regex" : @"required|true|false|yes|y|n|off|on",
                                                                                                         @"type" : @"type",
                                                                                                         }];

  NSMutableDictionary<NSString *, NSString *> *rule2 =  [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                                         @"key_regex" : @"^phone$|phone number|cell phone|mobile phone|^mobile$",
                                                                                                         @"value_negative_regex" : @"required|true|false|yes|y|n|off|on",
                                                                                                         @"type" : @"type",
                                                                                                         }];

  [rules addObject:rule1];
  [rules addObject:rule2];
  [FBSDKRestrictiveDataFilterManager updateFilters:rules restrictiveParams:nil];


  id mockAppStates = [OCMockObject niceMockForClass:[FBSDKAppEventsState class]];
  OCMStub([mockAppStates alloc]).andReturn(mockAppStates);
  OCMStub([mockAppStates initWithToken:[OCMArg any] appID:[OCMArg any]]).andReturn(mockAppStates);


  // filtered by key
  [[mockAppStates expect] addEvent:[OCMArg checkWithBlock:^(id value){
    XCTAssertEqualObjects(value[@"_eventName"], @"test_event_1");
    XCTAssertNil(value[@"phone"]);
    XCTAssertEqualObjects(value[@"_restrictedParams"], @"{\"phone\":\"type\"}");
    return YES;
  }] isImplicit:NO];
  [FBSDKAppEvents logEvent:@"test_event_1" parameters:@{@"phone" : @"123-234"}];
  [mockAppStates verify];

  // filtered by value
  [[mockAppStates expect] addEvent:[OCMArg checkWithBlock:^(id value){
    XCTAssertEqualObjects(value[@"_eventName"], @"test_event_2");
    XCTAssertNil(value[@"key"]);
    XCTAssertEqualObjects(value[@"_restrictedParams"], @"{\"key\":\"type\"}");
    return YES;
  }] isImplicit:NO];
  [FBSDKAppEvents logEvent:@"test_event_2" parameters:@{@"key": @"yes"}];
  [mockAppStates verify];

  // should not be filtered
  [[mockAppStates expect] addEvent:[OCMArg checkWithBlock:^(id value){
    XCTAssertEqualObjects(value[@"_eventName"], @"test_event_3");
    XCTAssertEqualObjects(value[@"_valueToSum"], @1);
    XCTAssertEqualObjects(value[@"number"], @"0629");
    XCTAssertNil(value[@"_restrictedParams"]);
    return YES;
  }] isImplicit:NO];
  [FBSDKAppEvents logEvent:@"test_event_3" valueToSum:1 parameters:@{@"number" : @"0629"}];
  [mockAppStates verify];
}

- (void)testFilterByParams
{
  NSString *testEventName = @"restrictive_event_name";
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary: @{ testEventName : @{@"restrictive_param" :@{@"dob" : @4}}}];

  [FBSDKRestrictiveDataFilterManager updateFilters:nil restrictiveParams:params];

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
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
  NSString *eventName = @"test_event_name";

  NSMutableDictionary<NSString *, NSString *> *restrictiveParams = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                                                   @"first name" : @"6",
                                                                                                                   @"last name" : @"7"
                                                                                                                   }];
  NSMutableDictionary<NSString *, id> *paramsDict = [NSMutableDictionary dictionary];;
  [FBSDKBasicUtility dictionary:paramsDict setObject:restrictiveParams forKey:@"restrictive_param"];
  [FBSDKBasicUtility dictionary:params setObject:paramsDict forKey:eventName];

  [FBSDKRestrictiveDataFilterManager updateFilters:nil restrictiveParams:params];

  NSString *type1 = [FBSDKRestrictiveDataFilterManager getMatchedDataTypeWithEventName:eventName paramKey:@"first name" paramValue:@""];
  XCTAssertEqualObjects(type1, @"6");

  NSString *type2= [FBSDKRestrictiveDataFilterManager getMatchedDataTypeWithEventName:eventName paramKey:@"reservation number" paramValue:@"123"];
  XCTAssertNil(type2);
}

- (void)testIsDeprecatedEvent
{
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
  NSString *eventName = @"test_event_name";

  NSMutableDictionary<NSString *, NSString *> *restrictiveParams = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                                                    @"first name" : @"6",
                                                                                                                    @"last name" : @"7"
                                                                                                                    }];
  NSString *deprecatedEventName = @"deprecated_event_name";
  NSMutableDictionary<NSString *, NSString *> *deprecatedEvent = [NSMutableDictionary dictionaryWithDictionary: @{@"is_deprecated_event" : @YES}];

  NSMutableDictionary<NSString *, id> *paramsDict = [NSMutableDictionary dictionary];;
  [FBSDKBasicUtility dictionary:paramsDict setObject:restrictiveParams forKey:@"restrictive_param"];
  [FBSDKBasicUtility dictionary:params setObject:paramsDict forKey:eventName];
  [FBSDKBasicUtility dictionary:params setObject:deprecatedEvent forKey:deprecatedEventName];

  [FBSDKRestrictiveDataFilterManager updateFilters:nil restrictiveParams:params];

  XCTAssertTrue([FBSDKRestrictiveDataFilterManager isDeprecatedEvent:deprecatedEventName]);
  XCTAssertFalse([FBSDKRestrictiveDataFilterManager isDeprecatedEvent:eventName]);
}

@end
