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

#import "FBSDKAppEventsUtilityTests.h"

#import <AdSupport/AdSupport.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKCoreKitTests-Swift.h"

static NSString *const FBSDKSettingsInstallTimestamp = @"com.facebook.sdk:FBSDKSettingsInstallTimestamp";
static NSString *const FBSDKSettingsAdvertisingTrackingStatus = @"com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus";

@interface TestASIdentifierManager : ASIdentifierManager

@property (nonatomic) NSUUID *stubbedAdvertisingIdentifier;

@end

@implementation TestASIdentifierManager

- (NSUUID *)advertisingIdentifier
{
  return self.stubbedAdvertisingIdentifier;
}

@end

@interface FBSDKAppEvents (Testing)

+ (void)setSingletonInstanceToInstance:(FBSDKAppEvents *)appEvents;
- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds;

@end

@interface FBSDKSettings ()
+ (void)resetAdvertiserTrackingStatusCache;
+ (void)setAdvertiserTrackingStatus:(FBSDKAdvertisingTrackingStatus)status;
@end

@interface FBSDKAppEventsConfiguration ()
- (void)setDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)status;
@end

@interface FBSDKAppEventsConfigurationManager ()
@property (nonnull, nonatomic) FBSDKAppEventsConfiguration *configuration;
@end

@implementation FBSDKAppEventsUtilityTests

+ (void)setUp
{
  [super setUp];

  FBSDKAppEventsUtility.cachedAdvertiserIdentifierManager = nil;
}

- (void)setUp
{
  [super setUp];

  self.userDefaultsSpy = [UserDefaultsSpy new];
  self.bundle = [TestBundle new];
  self.logger = [TestEventLogger new];
  self.appEventsStateProvider = [TestAppEventsStateProvider new];
  TestAppEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.valid;

  [FBSDKSettings configureWithStore:self.userDefaultsSpy
     appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
             infoDictionaryProvider:self.bundle
                        eventLogger:self.logger];

  FBSDKAppEvents *appEvents = [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                                                       flushPeriodInSeconds:0];
  FBSDKAppEvents.singletonInstanceToInstance = appEvents;
  [FBSDKAppEvents.shared configureWithGateKeeperManager:TestGateKeeperManager.self
                         appEventsConfigurationProvider:TestAppEventsConfigurationProvider.self
                            serverConfigurationProvider:TestServerConfigurationProvider.self
                                    graphRequestFactory:[TestGraphRequestFactory new]
                                         featureChecker:[TestFeatureManager new]
                                                  store:self.userDefaultsSpy
                                                 logger:TestLogger.class
                                               settings:[TestSettings new]
                                        paymentObserver:[TestPaymentObserver new]
                               timeSpentRecorderFactory:[TestTimeSpentRecorderFactory new]
                                    appEventsStateStore:[TestAppEventsStateStore new]
                    eventDeactivationParameterProcessor:[TestAppEventsParameterProcessor new]
                restrictiveDataFilterParameterProcessor:[TestAppEventsParameterProcessor new]
                                    atePublisherFactory:[TestAtePublisherFactory new]
                                 appEventsStateProvider:self.appEventsStateProvider
                                               swizzler:TestSwizzler.class
                                   advertiserIDProvider:FBSDKAppEventsUtility.shared];
}

- (void)tearDown
{
  [FBSDKAppEvents reset];
  [TestAppEventsConfigurationProvider reset];
  [TestGateKeeperManager reset];
  FBSDKAppEventsUtility.cachedAdvertiserIdentifierManager = nil;
  [FBSDKSettings reset];
  [FBSDKAppEventsConfigurationManager reset];

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
  FBSDKSettings.shouldUseCachedValuesForExpensiveMetadata = YES;
  FBSDKAppEventsConfigurationManager.shared.configuration = [SampleAppEventsConfigurations createWithAdvertiserIDCollectionEnabled:YES];

  NSString *identifier = @"68753A44-4D6F-1226-9C60-0050E4C00067";
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:identifier];
  TestASIdentifierManager *identifierManager = [TestASIdentifierManager new];
  identifierManager.stubbedAdvertisingIdentifier = uuid;
  FBSDKAppEventsUtility.cachedAdvertiserIdentifierManager = identifierManager;
  NSDictionary<NSString *, id> *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                         shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNotNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);
  XCTAssertEqualObjects(
    @"com.facebook.sdk.appevents.userid",
    dict[@"app_user_id"],
    "Parameters should use the user id set on the AppEvents singleton instance"
  );
  XCTAssertEqualObjects(@"{}", dict[@"ud"]);

  NSString *testEmail = @"apptest@fb.com";
  NSString *testFirstName = @"test_fn";
  NSString *testLastName = @"test_ln";
  NSString *testPhone = @"123";
  NSString *testGender = @"m";
  NSString *testCity = @"menlopark";
  NSString *testState = @"test_s";
  NSString *testExternalId = @"facebook123";
  [FBSDKAppEvents.shared setUserData:testEmail forType:FBSDKAppEventEmail];
  [FBSDKAppEvents.shared setUserData:testFirstName forType:FBSDKAppEventFirstName];
  [FBSDKAppEvents.shared setUserData:testLastName forType:FBSDKAppEventLastName];
  [FBSDKAppEvents.shared setUserData:testPhone forType:FBSDKAppEventPhone];
  [FBSDKAppEvents.shared setUserData:testGender forType:FBSDKAppEventGender];
  [FBSDKAppEvents.shared setUserData:testCity forType:FBSDKAppEventCity];
  [FBSDKAppEvents.shared setUserData:testState forType:FBSDKAppEventState];
  [FBSDKAppEvents.shared setUserData:testExternalId forType:FBSDKAppEventExternalId];
  dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                           shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNotNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);
  NSDictionary<NSString *, NSString *> *expectedUserDataDict = @{@"em" : [FBSDKUtility SHA256Hash:testEmail],
                                                                 @"fn" : [FBSDKUtility SHA256Hash:testFirstName],
                                                                 @"ln" : [FBSDKUtility SHA256Hash:testLastName],
                                                                 @"ph" : [FBSDKUtility SHA256Hash:testPhone],
                                                                 @"ge" : [FBSDKUtility SHA256Hash:testGender],
                                                                 @"ct" : [FBSDKUtility SHA256Hash:testCity],
                                                                 @"st" : [FBSDKUtility SHA256Hash:testState],
                                                                 @"external_id" : [FBSDKUtility SHA256Hash:testExternalId]};
  NSDictionary<NSString *, NSString *> *actualUserDataDict = (NSDictionary<NSString *, NSString *> *)[FBSDKTypeUtility JSONObjectWithData:[dict[@"ud"] dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                    options: NSJSONReadingMutableContainers
                                                                                                    error: nil];
  XCTAssertEqualObjects(actualUserDataDict, expectedUserDataDict);
  [FBSDKAppEvents.shared clearUserData];

  FBSDKSettings.limitEventAndDataUsage = YES;
  [FBSDKSettings setDataProcessingOptions:@[@"LDU"] country:100 state:1];
  dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event2"
                                           shouldAccessAdvertisingID:NO];
  XCTAssertEqualObjects(@"event2", dict[@"event"]);
  XCTAssertNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"0", dict[@"application_tracking_enabled"]);
  XCTAssertEqualObjects(@"[\"LDU\"]", dict[@"data_processing_options"]);
  XCTAssertTrue([(NSNumber *)dict[@"data_processing_options_country"] isEqualToNumber:[NSNumber numberWithInt:100]]);
  XCTAssertTrue([(NSNumber *)dict[@"data_processing_options_state"] isEqualToNumber:[NSNumber numberWithInt:1]]);

  FBSDKSettings.limitEventAndDataUsage = NO;
  FBSDKSettings.dataProcessingOptions = @[];
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
  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithAdvertiserIDCollectionEnabled:YES];
  FBSDKAppEventsConfigurationManager.shared.configuration = configuration;

  if (@available(iOS 14.0, *)) {
  #ifndef BUCK
    // This test fails in buck but passes in Xcode. Even if -FBSDKAppEventsUtility.advertiserID is set directly to ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString
    XCTAssertNotNil(
      [FBSDKAppEventsUtility.shared advertiserID],
      "Advertiser id should not be nil when collection is enabled"
    );
  #endif
  }
}

- (void)testGetAdvertiserIDOniOS14WithCollectionDisabled
{
  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:NO
                                                                                  eventCollectionEnabled:YES];
  FBSDKAppEventsConfigurationManager.shared.configuration = configuration;

  if (@available(iOS 14.0, *)) {
    XCTAssertNil([FBSDKAppEventsUtility.shared advertiserID]);
  }
}

- (void)testShouldDropAppEvent
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingDisallowed;

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:NO];
  FBSDKAppEventsConfigurationManager.shared.configuration = configuration;

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
    configuration.defaultATEStatus = defaultATEStatus.unsignedIntegerValue;
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
      NSDictionary<NSString *, id> *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
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
  // shouldDropAppEvent only when: advertisingTrackingStatus == Disallowed && FBSDKAppEventsConfiguration.eventCollectionEnabled == NO
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingDisallowed;
  FBSDKAppEventsConfigurationManager.shared.configuration = [SampleAppEventsConfigurations createWithEventCollectionEnabled:NO];

  FBSDKSettings.sharedSettings.appID = @"123";
  [FBSDKAppEvents logEvent:@"event"];

  XCTAssertFalse(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Shouldn't call addEvents on AppEventsState when dropping app event"
  );
}

- (void)testSendAppEventWhenTrackingUnspecified
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingUnspecified;
  FBSDKAppEventsConfigurationManager.shared.configuration = [SampleAppEventsConfigurations createWithEventCollectionEnabled:NO];

  FBSDKSettings.sharedSettings.appID = @"123";
  [FBSDKAppEvents logEvent:@"event"];

  XCTAssertTrue(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Should call addEvents on AppEventsState when sending app event"
  );
  XCTAssertFalse(
    self.appEventsStateProvider.state.capturedIsImplicit,
    "Shouldn't implicitly call addEvents on AppEventsState when sending app event"
  );
}

- (void)testSendAppEventWhenTrackingAllowed
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  FBSDKAppEventsConfigurationManager.shared.configuration = [SampleAppEventsConfigurations createWithEventCollectionEnabled:NO];

  FBSDKSettings.sharedSettings.appID = @"123";
  [FBSDKAppEvents logEvent:@"event"];

  XCTAssertTrue(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Should call addEvents on AppEventsState when sending app event"
  );
  XCTAssertFalse(
    self.appEventsStateProvider.state.capturedIsImplicit,
    "Shouldn't implicitly call addEvents on AppEventsState when sending app event"
  );
}

- (void)testSendAppEventWhenEventCollectionEnabled
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingDisallowed;
  FBSDKAppEventsConfigurationManager.shared.configuration = [SampleAppEventsConfigurations createWithEventCollectionEnabled:YES];

  FBSDKSettings.sharedSettings.appID = @"123";
  [FBSDKAppEvents logEvent:@"event"];
  XCTAssertTrue(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Should call addEvents on AppEventsState when sending app event"
  );
  XCTAssertFalse(
    self.appEventsStateProvider.state.capturedIsImplicit,
    "Shouldn't implicitly call addEvents on AppEventsState when sending app event"
  );
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
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an app id or client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithClientToken
{
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an app id"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithoutClientToken
{
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = SampleAccessTokens.validToken.appID;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without a client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithClientToken
{
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = @"abc";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    @"abc|toktok",
    "Should provide a token string with the app id and client token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithClientToken
{
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithoutClientToken
{
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithoutClientToken
{
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token when "
    "the app id on the token does not match the app id in settings"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientToken
{
  FBSDKAppEvents.loggingOverrideAppID = nil;
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token when "
    "the app id on the token does not match the app id in settings"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an access token, app id, or client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an access token or app id"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = SampleAccessTokens.validToken.appID;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without a client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = SampleAccessTokens.validToken.appID;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string with the logging app id and client token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAppEvents.loggingOverrideAppID = @"789";
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppIDMatching
{
  FBSDKAppEvents.loggingOverrideAppID = SampleAccessTokens.validToken.appID;
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the access token when the access token's app id matches the logging override"
  );
}

@end
