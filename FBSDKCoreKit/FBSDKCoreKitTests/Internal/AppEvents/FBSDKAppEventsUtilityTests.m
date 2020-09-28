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

// @lint-ignore-every CLANGTIDY
#import <AdSupport/AdSupport.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKTestCase.h"

static NSString *const FBSDKSettingsInstallTimestamp = @"com.facebook.sdk:FBSDKSettingsInstallTimestamp";
static NSString *const FBSDKSettingsAdvertisingTrackingStatus = @"com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus";

@interface FBSDKSettings ()
+ (void)resetAdvertiserTrackingStatusCache;
@end

@interface FBSDKAppEventsConfiguration ()
- (void)setDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)status;
@end

@interface FBSDKAppEventsUtilityTests : FBSDKTestCase

@end

@implementation FBSDKAppEventsUtilityTests
{
  id _mockAppEventsUtility;
  id _mockNSLocale;
}

- (void)setUp
{
  [super setUp];

  [self stubServerConfigurationFetchingWithConfiguration:[FBSDKServerConfiguration defaultServerConfigurationForAppID:nil] error:nil];

  _mockAppEventsUtility = OCMClassMock([FBSDKAppEventsUtility class]);
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
  OCMStub([_mockAppEventsUtility advertiserID]).andReturn([NSUUID UUID].UUIDString);
  id mockFBSDKSettings = OCMClassMock([FBSDKSettings class]);
  OCMStub([mockFBSDKSettings isAdvertiserTrackingEnabled]).andReturn(YES);

  OCMStub([_mockAppEventsUtility advertiserID]).andReturn([NSUUID UUID].UUIDString);
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

- (void)testGetAdvertiserIDOniOS14WithCollectionEnabled
{
  id mockFBSDKSettings = OCMClassMock([FBSDKSettings class]);
  OCMStub([mockFBSDKSettings isAdvertiserIDCollectionEnabled]).andReturn(YES);

  id mockAppEventsConfiguration = OCMClassMock([FBSDKAppEventsConfiguration class]);
  OCMStub([mockAppEventsConfiguration advertiserIDCollectionEnabled]).andReturn(YES);
  id mockAppEventsConfigurationManager = OCMClassMock([FBSDKAppEventsConfigurationManager class]);
  OCMStub([mockAppEventsConfigurationManager cachedAppEventsConfiguration]).andReturn(mockAppEventsConfiguration);
  id mockASIdentifierManager = OCMClassMock([ASIdentifierManager class]);
  OCMStub([mockASIdentifierManager advertisingIdentifier]).andReturn([NSUUID UUID]);
  OCMStub([mockASIdentifierManager sharedManager]).andReturn(mockASIdentifierManager);

  if (@available(iOS 14.0, *)) {
    XCTAssertNotNil(
      [FBSDKAppEventsUtility advertiserID],
      "Advertiser id should not be nil when collection is enabled"
    );
  }
}

- (void)testGetAdvertiserIDOniOS14WithCollectionDisabled
{
  id mockFBSDKSettings = OCMClassMock([FBSDKSettings class]);
  OCMStub([mockFBSDKSettings isAdvertiserIDCollectionEnabled]).andReturn(YES);

  id mockAppEventsConfiguration = OCMClassMock([FBSDKAppEventsConfiguration class]);
  OCMStub([mockAppEventsConfiguration advertiserIDCollectionEnabled]).andReturn(NO);
  id mockAppEventsConfigurationManager = OCMClassMock([FBSDKAppEventsConfigurationManager class]);
  OCMStub([mockAppEventsConfigurationManager cachedAppEventsConfiguration]).andReturn(mockAppEventsConfiguration);
  OCMStub([mockAppEventsConfigurationManager cachedAppEventsConfiguration]).andReturn(mockAppEventsConfiguration);
  id mockASIdentifierManager = OCMClassMock([ASIdentifierManager class]);
  OCMStub([mockASIdentifierManager advertisingIdentifier]).andReturn([NSUUID UUID]);
  OCMStub([mockASIdentifierManager sharedManager]).andReturn(mockASIdentifierManager);

  if (@available(iOS 14.0, *)) {
    XCTAssertNil([FBSDKAppEventsUtility advertiserID]);
  }
}

- (void)testShouldDropAppEvent
{
  id mockFBSDKSettings = OCMClassMock([FBSDKSettings class]);
  OCMStub([mockFBSDKSettings getAdvertisingTrackingStatus]).andReturn(FBSDKAdvertisingTrackingDisallowed);

  id mockAppEventsConfiguration = OCMClassMock([FBSDKAppEventsConfiguration class]);
  OCMStub([mockAppEventsConfiguration eventCollectionEnabled]).andReturn(NO);
  id mockAppEventsConfigurationManager = OCMClassMock([FBSDKAppEventsConfigurationManager class]);
  OCMStub([mockAppEventsConfigurationManager cachedAppEventsConfiguration]).andReturn(mockAppEventsConfiguration);

  if (@available(iOS 14.0, *)) {
    XCTAssertTrue([FBSDKAppEventsUtility shouldDropAppEvent]);
  } else {
    XCTAssertFalse([FBSDKAppEventsUtility shouldDropAppEvent]);
  }
}

- (void)testAdvertiserTrackingEnabledInAppEventPayload
{
  FBSDKAppEventsConfiguration *configuration = [[FBSDKAppEventsConfiguration alloc] initWithJSON:@{}];
  id mockAppEventsConfigurationManager = OCMClassMock([FBSDKAppEventsConfigurationManager class]);
  OCMStub([mockAppEventsConfigurationManager cachedAppEventsConfiguration]).andReturn(configuration);
  NSArray<NSNumber *> *statusList = @[@(FBSDKAdvertisingTrackingAllowed), @(FBSDKAdvertisingTrackingDisallowed), @(FBSDKAdvertisingTrackingUnspecified)];
  for (NSNumber *defaultATEStatus in statusList) {
    [configuration setDefaultATEStatus:defaultATEStatus.unsignedIntegerValue];
    for (NSNumber *status in statusList) {
      [FBSDKSettings resetAdvertiserTrackingStatusCache];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:FBSDKSettingsAdvertisingTrackingStatus];
      if ([status unsignedIntegerValue] != FBSDKAdvertisingTrackingUnspecified) {
        [FBSDKSettings setAdvertiserTrackingStatus:[status unsignedIntegerValue]];
      }
      NSDictionary *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                             shouldAccessAdvertisingID:YES];
      if (@available(iOS 14.0, *)) {
        // If status is unspecified, ATE will be defaultATEStatus
        if ([status unsignedIntegerValue] == FBSDKAdvertisingTrackingUnspecified) {
          if ([defaultATEStatus unsignedIntegerValue] == FBSDKAdvertisingTrackingUnspecified) {
            XCTAssertNil(dict[@"advertiser_tracking_enabled"], @"advertiser_tracking_enabled should not be attached to event payload if ATE is unspecified");
          } else {
            BOOL advertiserTrackingEnabled = defaultATEStatus.unsignedIntegerValue == FBSDKAdvertisingTrackingAllowed;
            XCTAssertTrue([@(advertiserTrackingEnabled).stringValue isEqualToString:[FBSDKTypeUtility dictionary:dict objectForKey:@"advertiser_tracking_enabled" ofType:NSString.class]], @"advertiser_tracking_enabled should be default value when ATE is not set");
          }
        } else {
          BOOL advertiserTrackingEnabled = status.unsignedIntegerValue == FBSDKAdvertisingTrackingAllowed;
          XCTAssertTrue([@(advertiserTrackingEnabled).stringValue isEqualToString:[FBSDKTypeUtility dictionary:dict objectForKey:@"advertiser_tracking_enabled" ofType:NSString.class]], @"advertiser_tracking_enabled should be equal to ATE explicitly setted via setAdvertiserTrackingStatus");
        }
      } else {
        XCTAssertNotNil(dict[@"advertiser_tracking_enabled"]);
      }
    }
  }
}

- (void)testDropAppEvent
{
  id mockAppEventsState = OCMClassMock([FBSDKAppEventsState class]);
  OCMStub([mockAppEventsState alloc]).andReturn(mockAppEventsState);
  OCMStub([mockAppEventsState initWithToken:OCMArg.any appID:OCMArg.any]).andReturn(mockAppEventsState);
  [FBSDKSettings setAppID:@"123"];

  OCMStub([_mockAppEventsUtility shouldDropAppEvent]).andReturn(YES);
  [FBSDKAppEvents logEvent:@"event"];
  OCMReject([mockAppEventsState addEvent:OCMArg.any isImplicit:NO]);
}

- (void)testSendAppEvent
{
  id mockAppEventsState = OCMClassMock([FBSDKAppEventsState class]);
  OCMStub([mockAppEventsState alloc]).andReturn(mockAppEventsState);
  OCMStub([mockAppEventsState initWithToken:OCMArg.any appID:OCMArg.any]).andReturn(mockAppEventsState);
  [FBSDKSettings setAppID:@"123"];

  OCMStub([_mockAppEventsUtility shouldDropAppEvent]).andReturn(NO);
  [FBSDKAppEvents logEvent:@"event"];
  OCMVerify([mockAppEventsState addEvent:OCMArg.any isImplicit:NO]);
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

- (void)testGetStandardEvents
{
  NSArray<NSString *> *standardEvents = @[
    @"fb_mobile_complete_registration",
    @"fb_mobile_content_view",
    @"fb_mobile_search",
    @"fb_mobile_rate",
    @"fb_mobile_tutorial_completion",
    @"fb_mobile_add_to_cart",
    @"fb_mobile_add_to_wishlist",
    @"fb_mobile_initiated_checkout",
    @"fb_mobile_add_payment_info",
    @"fb_mobile_purchase",
    @"fb_mobile_level_achieved",
    @"fb_mobile_achievement_unlocked",
    @"fb_mobile_spent_credits",
    @"Contact",
    @"CustomizeProduct",
    @"Donate",
    @"FindLocation",
    @"Schedule",
    @"StartTrial",
    @"SubmitApplication",
    @"Subscribe",
    @"AdImpression",
    @"AdClick",
  ];
  for (NSString *event in standardEvents) {
    XCTAssertTrue([FBSDKAppEventsUtility isStandardEvent:event]);
  }
}

@end
