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
@import TestTools;

#import <AdSupport/AdSupport.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"

static NSString *const FBSDKSettingsInstallTimestamp = @"com.facebook.sdk:FBSDKSettingsInstallTimestamp";
static NSString *const FBSDKSettingsAdvertisingTrackingStatus = @"com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus";

@interface FBSDKSettings ()
+ (void)resetAdvertiserTrackingStatusCache;
@end

@interface FBSDKAppEventsConfiguration ()
- (void)setDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)status;
@end

@implementation FBSDKAppEventsUtilityTests
{
  UserDefaultsSpy *userDefaultsSpy;
  TestBundle *bundle;
  TestEventLogger *logger;
}

+ (void)setUp
{
  [super setUp];

  FBSDKAppEventsUtility.cachedAdvertiserIdentifierManager = nil;
}

- (void)setUp
{
  self.shouldAppEventsMockBePartial = YES;

  [super setUp];

  [self stubServerConfigurationFetchingWithConfiguration:[FBSDKServerConfiguration defaultServerConfigurationForAppID:nil] error:nil];

  [FBSDKAppEvents setUserID:@"test-user-id"];

  userDefaultsSpy = [UserDefaultsSpy new];
  bundle = [TestBundle new];
  logger = [TestEventLogger new];
  TestAppEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.valid;

  [FBSDKSettings configureWithStore:userDefaultsSpy
     appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
             infoDictionaryProvider:bundle
                        eventLogger:logger];
  [FBSDKAppEvents configureWithGateKeeperManager:TestGateKeeperManager.self
                  appEventsConfigurationProvider:TestAppEventsConfigurationProvider.self
                     serverConfigurationProvider:TestServerConfigurationProvider.self
                            graphRequestProvider:[TestGraphRequestFactory new]
                                  featureChecker:TestFeatureManager.class
                                           store:userDefaultsSpy
                                          logger:TestLogger.class];
}

- (void)tearDown
{
  [self.appEventsUtilityClassMock stopMocking];
  [FBSDKAppEvents reset];
  [TestAppEventsConfigurationProvider reset];
  [TestServerConfigurationProvider reset];
  FBSDKAppEventsUtility.cachedAdvertiserIdentifierManager = nil;

  [super tearDown];
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
  [self stubAdvertiserIdentifierWithIdentifierString:NSUUID.UUID.UUIDString];
  [self stubIsAdvertiserTrackingEnabledWith:YES];
  [self stubAdvertiserIdentifierWithIdentifierString:NSUUID.UUID.UUIDString];
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

- (void)testGetAdvertiserIDOniOS14WithCollectionEnabled
{
  [self stubIsAdvertiserIDCollectionEnabledWith:YES];
  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:YES];
  [self stubCachedAppEventsConfigurationWithConfiguration:configuration];
  [self stubAdvertisingIdentifierWithIdentifier:NSUUID.UUID];
  [self stubSharedAsIdentifierManagerWithAsIdentifierManager:self.asIdentifierManagerClassMock];

  if (@available(iOS 14.0, *)) {
    XCTAssertNotNil(
      [FBSDKAppEventsUtility advertiserID],
      "Advertiser id should not be nil when collection is enabled"
    );
  }
}

- (void)testGetAdvertiserIDOniOS14WithCollectionDisabled
{
  [self stubIsAdvertiserTrackingEnabledWith:YES];

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:NO
                                                                                  eventCollectionEnabled:YES];
  [self stubCachedAppEventsConfigurationWithConfiguration:configuration];
  [self stubAdvertisingIdentifierWithIdentifier:NSUUID.UUID];
  [self stubSharedAsIdentifierManagerWithAsIdentifierManager:self.asIdentifierManagerClassMock];

  if (@available(iOS 14.0, *)) {
    XCTAssertNil([FBSDKAppEventsUtility advertiserID]);
  }
}

- (void)testShouldDropAppEvent
{
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingDisallowed];

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:NO];
  [self stubCachedAppEventsConfigurationWithConfiguration:configuration];

  if (@available(iOS 14.0, *)) {
    XCTAssertTrue([FBSDKAppEventsUtility shouldDropAppEvent]);
  } else {
    XCTAssertFalse([FBSDKAppEventsUtility shouldDropAppEvent]);
  }
}

- (void)testAdvertiserTrackingEnabledInAppEventPayload
{
  FBSDKAppEventsConfiguration *configuration = [[FBSDKAppEventsConfiguration alloc] initWithJSON:@{}];

  NSArray<NSNumber *> *statusList = @[@(FBSDKAdvertisingTrackingAllowed), @(FBSDKAdvertisingTrackingDisallowed), @(FBSDKAdvertisingTrackingUnspecified)];
  for (NSNumber *defaultATEStatus in statusList) {
    [configuration setDefaultATEStatus:defaultATEStatus.unsignedIntegerValue];
    for (NSNumber *status in statusList) {
      TestAppEventsConfigurationProvider.stubbedConfiguration = configuration;
      [FBSDKSettings reset];
      [FBSDKSettings configureWithStore:[UserDefaultsSpy new]
         appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
                 infoDictionaryProvider:[TestBundle new]
                            eventLogger:[TestEventLogger new]];

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
  [FBSDKSettings setAppID:@"123"];

  [self stubAppEventsUtilityShouldDropAppEventWith:YES];
  [FBSDKAppEvents logEvent:@"event"];
  OCMReject([self.appEventStatesMock addEvent:OCMArg.any isImplicit:NO]);
}

- (void)testSendAppEvent
{
  [FBSDKSettings setAppID:@"123"];

  [self stubAppEventsUtilityShouldDropAppEventWith:NO];
  [FBSDKAppEvents logEvent:@"event"];
  OCMVerify([self.appEventStatesMock addEvent:OCMArg.any isImplicit:NO]);
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

// MARK: - Token Strings

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an app id or client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an app id"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithoutClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:@"123"];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without a client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:@"123"];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    @"123|toktok",
    "Should provide a token string with the app id and client token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.appID,
    "Should provide a token string with the access token's app id"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithoutClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.appID,
    "Should provide a token string with the access token's app id"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithoutClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:@"456"];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.appID,
    "Should provide a token string with the access token's app id"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientToken
{
  [FBSDKAppEvents setLoggingOverrideAppID:nil];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:@"456"];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.appID,
    "Should provide a token string with the access token's app id"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an app id or client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string with the logging app id and client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:@"123"];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without a client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:@"123"];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string with the logging app id and client token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:@"456"];
  [FBSDKSettings setClientToken:nil];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppID
{
  [FBSDKAppEvents setLoggingOverrideAppID:@"789"];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:@"456"];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppIDMatching
{
  [FBSDKAppEvents setLoggingOverrideAppID:SampleAccessTokens.validToken.appID];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessTokens.validToken];
  [FBSDKSettings setAppID:@"456"];
  [FBSDKSettings setClientToken:@"toktok"];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.appID,
    "Should provide a token string with the access token's app id when the logging override matches it"
  );
}

@end
