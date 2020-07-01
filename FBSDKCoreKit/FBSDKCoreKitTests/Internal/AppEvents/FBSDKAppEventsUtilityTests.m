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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKAppEvents.h>
#import <FBSDKCoreKit/FBSDKSettings.h>

#import "FBSDKAppEventsUtility.h"
#import "FBSDKTypeUtility.h"
#import "FBSDKUtility.h"

@interface FBSDKAppEventsUtilityTests : XCTestCase

@end

@implementation FBSDKAppEventsUtilityTests
{
  id _mockAppEventsUtility;
  id _mockNSLocale;
}

- (void)setUp
{
  [super setUp];
  _mockAppEventsUtility = OCMClassMock([FBSDKAppEventsUtility class]);
  OCMStub([_mockAppEventsUtility advertiserID]).andReturn([NSUUID UUID].UUIDString);
  [FBSDKAppEvents setUserID:@"test-user-id"];
  _mockNSLocale = OCMClassMock([NSLocale class]);
}

- (void)tearDown
{
  [super tearDown];

  [_mockNSLocale stopMocking];
  [_mockAppEventsUtility stopMocking];
}

- (void)testLogNotification
{
  [self expectationForNotification:FBSDKAppEventsLoggingResultNotification object:nil handler:nil];

  [FBSDKAppEventsUtility logAndNotify:@"test"];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
  }];
}

- (void)testValidation
{
  XCTAssertFalse([FBSDKAppEventsUtility validateIdentifier:@"x-9adc++|!@#"]);
  XCTAssertTrue([FBSDKAppEventsUtility validateIdentifier:@"4simple id_-3"]);
  XCTAssertTrue([FBSDKAppEventsUtility validateIdentifier:@"_4simple id_-3"]);
  XCTAssertFalse([FBSDKAppEventsUtility validateIdentifier:@"-4simple id_-3"]);
}

- (void)testParamsDictionary
{
  NSDictionary *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                         shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNotNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);
  XCTAssertEqualObjects(@"test-user-id", dict[@"app_user_id"]);
  XCTAssertEqualObjects(@"{}", dict[@"ud"]);

  NSString *testEmail = @"apptest@fb.com";
  NSString *testFirstName = @"test_fn";
  NSString *testLastName = @"test_ln";
  NSString *testPhone = @"123";
  NSString *testGender = @"m";
  NSString *testCity = @"menlopark";
  NSString *testState = @"test_s";
  [FBSDKAppEvents setUserData:testEmail forType:FBSDKAppEventEmail];
  [FBSDKAppEvents setUserData:testFirstName forType:FBSDKAppEventFirstName];
  [FBSDKAppEvents setUserData:testLastName forType:FBSDKAppEventLastName];
  [FBSDKAppEvents setUserData:testPhone forType:FBSDKAppEventPhone];
  [FBSDKAppEvents setUserData:testGender forType:FBSDKAppEventGender];
  [FBSDKAppEvents setUserData:testCity forType:FBSDKAppEventCity];
  [FBSDKAppEvents setUserData:testState forType:FBSDKAppEventState];
  dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                           shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNotNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);
  XCTAssertEqualObjects(@"test-user-id", dict[@"app_user_id"]);
  NSDictionary<NSString *, NSString *> *expectedUserDataDict = @{@"em" : [FBSDKUtility SHA256Hash:testEmail],
                                                                 @"fn" : [FBSDKUtility SHA256Hash:testFirstName],
                                                                 @"ln" : [FBSDKUtility SHA256Hash:testLastName],
                                                                 @"ph" : [FBSDKUtility SHA256Hash:testPhone],
                                                                 @"ge" : [FBSDKUtility SHA256Hash:testGender],
                                                                 @"ct" : [FBSDKUtility SHA256Hash:testCity],
                                                                 @"st" : [FBSDKUtility SHA256Hash:testState]};
  NSDictionary<NSString *, NSString *> *actualUserDataDict = (NSDictionary<NSString *, NSString *> *)[FBSDKTypeUtility JSONObjectWithData:[dict[@"ud"] dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                    options: NSJSONReadingMutableContainers
                                                                                                    error: nil];
  XCTAssertEqualObjects(actualUserDataDict, expectedUserDataDict);
  [FBSDKAppEvents clearUserData];

  [FBSDKSettings setLimitEventAndDataUsage:YES];
  [FBSDKSettings setDataProcessingOptions:@[@"LDU"] country:100 state:1];
  dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event2"
                                           shouldAccessAdvertisingID:NO];
  XCTAssertEqualObjects(@"event2", dict[@"event"]);
  XCTAssertNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"0", dict[@"application_tracking_enabled"]);
  XCTAssertEqualObjects(@"[\"LDU\"]", dict[@"data_processing_options"]);
  XCTAssertTrue([(NSNumber *)dict[@"data_processing_options_country"] isEqualToNumber:[NSNumber numberWithInt:100]]);
  XCTAssertTrue([(NSNumber *)dict[@"data_processing_options_state"] isEqualToNumber:[NSNumber numberWithInt:1]]);

  [FBSDKSettings setLimitEventAndDataUsage:NO];
  [FBSDKSettings setDataProcessingOptions:@[]];
  dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                           shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNotNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);
  XCTAssertEqualObjects(@"[]", dict[@"data_processing_options"]);
  XCTAssertTrue([(NSNumber *)dict[@"data_processing_options_country"] isEqualToNumber:[NSNumber numberWithInt:0]]);
  XCTAssertTrue([(NSNumber *)dict[@"data_processing_options_state"] isEqualToNumber:[NSNumber numberWithInt:0]]);

  [FBSDKAppEvents clearUserID];
  dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                           shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNotNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);
  XCTAssertNil(dict[@"app_user_id"]);
}

- (void)testLogImplicitEventsExists
{
  Class FBSDKAppEventsClass = NSClassFromString(@"FBSDKAppEvents");
  SEL logEventSelector = NSSelectorFromString(@"logImplicitEvent:valueToSum:parameters:accessToken:");
  XCTAssertTrue([FBSDKAppEventsClass respondsToSelector:logEventSelector]);
}

- (void)testGetNumberValue
{
  NSNumber *result = [FBSDKAppEventsUtility
                      getNumberValue:@"Price: $1,234.56; Buy 1 get 2!"];
  NSString *str = [NSString stringWithFormat:@"%.2f", result.floatValue];
  XCTAssertTrue([str isEqualToString:@"1234.56"]);
}

#if BUCK
- (void)testGetNumberValueWithLocaleFR
{
  OCMStub(ClassMethod([_mockNSLocale currentLocale])).andReturn([NSLocale localeWithLocaleIdentifier:@"fr"]);

  NSNumber *result = [FBSDKAppEventsUtility
                      getNumberValue:@"Price: 1\u202F234,56; Buy 1 get 2!"];
  NSString *str = [NSString stringWithFormat:@"%.2f", result.floatValue];
  XCTAssertEqualObjects(str, @"1234.56");
}

#endif

- (void)testGetNumberValueWithLocaleIT
{
  OCMStub([_mockNSLocale currentLocale]).
  _andReturn(OCMOCK_VALUE([NSLocale localeWithLocaleIdentifier:@"it"]));

  NSNumber *result = [FBSDKAppEventsUtility
                      getNumberValue:@"Price: 1.234,56; Buy 1 get 2!"];
  NSString *str = [NSString stringWithFormat:@"%.2f", result.floatValue];
  XCTAssertEqualObjects(str, @"1234.56");
}

- (void)testIsSensitiveUserData
{
  NSString *text = @"test@sample.com";
  XCTAssertTrue([FBSDKAppEventsUtility isSensitiveUserData:text]);

  text = @"4716 5255 0221 9085";
  XCTAssertTrue([FBSDKAppEventsUtility isSensitiveUserData:text]);

  text = @"4716525502219085";
  XCTAssertTrue([FBSDKAppEventsUtility isSensitiveUserData:text]);

  text = @"4716525502219086";
  XCTAssertFalse([FBSDKAppEventsUtility isSensitiveUserData:text]);

  text = @"";
  XCTAssertFalse([FBSDKAppEventsUtility isSensitiveUserData:text]);

  // number of digits less than 9 will not be considered as credit card number
  text = @"4716525";
  XCTAssertFalse([FBSDKAppEventsUtility isSensitiveUserData:text]);
}

- (void)testFlushReasonToString
{
  NSString *result1 = [FBSDKAppEventsUtility flushReasonToString:FBSDKAppEventsFlushReasonExplicit];
  XCTAssertEqualObjects(@"Explicit", result1);

  NSString *result2 = [FBSDKAppEventsUtility flushReasonToString:FBSDKAppEventsFlushReasonTimer];
  XCTAssertEqualObjects(@"Timer", result2);

  NSString *result3 = [FBSDKAppEventsUtility flushReasonToString:FBSDKAppEventsFlushReasonSessionChange];
  XCTAssertEqualObjects(@"SessionChange", result3);

  NSString *result4 = [FBSDKAppEventsUtility flushReasonToString:FBSDKAppEventsFlushReasonPersistedEvents];
  XCTAssertEqualObjects(@"PersistedEvents", result4);

  NSString *result5 = [FBSDKAppEventsUtility flushReasonToString:FBSDKAppEventsFlushReasonEventThreshold];
  XCTAssertEqualObjects(@"EventCountThreshold", result5);

  NSString *result6 = [FBSDKAppEventsUtility flushReasonToString:FBSDKAppEventsFlushReasonEagerlyFlushingEvent];
  XCTAssertEqualObjects(@"EagerlyFlushingEvent", result6);
}

@end
