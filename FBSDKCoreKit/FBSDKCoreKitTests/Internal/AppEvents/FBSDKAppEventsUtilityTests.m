/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// @lint-ignore-every CLANGTIDY
@import TestTools;

#import "FBSDKAppEventsUtilityTests.h"

#import <AdSupport/AdSupport.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEvents+Testing.h"
#import "FBSDKAppEventsConfiguration+Testing.h"
#import "FBSDKAppEventsConfigurationManager+Testing.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKSettings+Testing.h"

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
  self.appEventsConfigurationProvider = [TestAppEventsConfigurationProvider new];
  self.appEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.valid;
  FBSDKAppEventsUtility.shared.appEventsConfigurationProvider = self.appEventsConfigurationProvider;

  [FBSDKSettings configureWithStore:self.userDefaultsSpy
     appEventsConfigurationProvider:self.appEventsConfigurationProvider
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
                                   advertiserIDProvider:FBSDKAppEventsUtility.shared
                                          userDataStore:[TestUserDataStore new]];
}

- (void)tearDown
{
  [FBSDKAppEvents reset];
  [TestGateKeeperManager reset];
  FBSDKAppEventsUtility.cachedAdvertiserIdentifierManager = nil;
  [FBSDKSettings.sharedSettings reset];
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

- (void)testActivityParametersWithoutUserID
{
  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertNil(
    parameters[@"app_user_id"],
    "Parameters should use not have a default user id"
  );
}

- (void)testActivityParametersWithUserID
{
  NSString *userID = NSUUID.UUID.UUIDString;
  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:userID
                                                                                                userData:nil];
  XCTAssertEqualObjects(
    userID,
    parameters[@"app_user_id"],
    "Parameters should use the provided user id"
  );
}

- (void)testActivityParametersWithoutUserData
{
  NSDictionary<NSString *, id> *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                         shouldAccessAdvertisingID:YES
                                                                                            userID:nil
                                                                                          userData:nil];
  XCTAssertEqualObjects(
    @"{}",
    dict[@"ud"],
    "Should represent missing user data as an empty dictionary"
  );
}

- (void)testActivityParametersWithUserData
{
  NSString *testEmail = @"apptest@fb.com";
  NSString *testFirstName = @"test_fn";
  NSString *testLastName = @"test_ln";
  NSString *testPhone = @"123";
  NSString *testGender = @"m";
  NSString *testCity = @"menlopark";
  NSString *testState = @"test_s";
  NSString *testExternalId = @"facebook123";
  FBSDKUserDataStore *store = [FBSDKUserDataStore new];

  [store setUserData:testEmail forType:FBSDKAppEventEmail];
  [store setUserData:testFirstName forType:FBSDKAppEventFirstName];
  [store setUserData:testLastName forType:FBSDKAppEventLastName];
  [store setUserData:testPhone forType:FBSDKAppEventPhone];
  [store setUserData:testGender forType:FBSDKAppEventGender];
  [store setUserData:testCity forType:FBSDKAppEventCity];
  [store setUserData:testState forType:FBSDKAppEventState];
  [store setUserData:testExternalId forType:FBSDKAppEventExternalId];
  NSString *hashedUserData = [store getUserData];

  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:nil
                                                                                                userData:hashedUserData];

  // TODO: These should be moved to the UserDataStoreTests since this is really just checking that we
  // store various user data fields as hashed strings
  NSDictionary<NSString *, NSString *> *expectedUserDataDict = @{@"em" : [FBSDKUtility SHA256Hash:testEmail],
                                                                 @"fn" : [FBSDKUtility SHA256Hash:testFirstName],
                                                                 @"ln" : [FBSDKUtility SHA256Hash:testLastName],
                                                                 @"ph" : [FBSDKUtility SHA256Hash:testPhone],
                                                                 @"ge" : [FBSDKUtility SHA256Hash:testGender],
                                                                 @"ct" : [FBSDKUtility SHA256Hash:testCity],
                                                                 @"st" : [FBSDKUtility SHA256Hash:testState],
                                                                 @"external_id" : [FBSDKUtility SHA256Hash:testExternalId]};
  NSDictionary<NSString *, NSString *> *actualUserDataDict = (NSDictionary<NSString *, NSString *> *)[FBSDKTypeUtility JSONObjectWithData:[parameters[@"ud"] dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                    options: NSJSONReadingMutableContainers
                                                                                                    error: nil];
  XCTAssertEqualObjects(actualUserDataDict, expectedUserDataDict);
}

- (void)testParametersDictionaryWithApplicationTrackingEnabled
{
  FBSDKSettings.sharedSettings.isEventDataUsageLimited = NO;

  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertEqualObjects(
    @"1",
    parameters[@"application_tracking_enabled"],
    "Application tracking is considered enabled when event data usage is not limited"
  );
}

- (void)testParametersDictionaryWithApplicationTrackingDisabled
{
  FBSDKSettings.sharedSettings.isEventDataUsageLimited = YES;

  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertEqualObjects(
    @"0",
    parameters[@"application_tracking_enabled"],
    "Application tracking is considered disabled when event data usage is limited"
  );
}

- (void)testParametersDictionaryWithAccessibleAdvertiserID
{
  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertEqualObjects(@"event", parameters[@"event"]);
  XCTAssertEqualObjects(
    parameters[@"advertiser_id"],
    @"00000000-0000-0000-0000-000000000000",
    "Should attempt to return an advertiser ID when allowed"
  );
}

- (void)testParametersDictionaryWithInaccessibleAdvertiserID
{
  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:NO
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertEqualObjects(@"event", parameters[@"event"]);
  XCTAssertNil(
    parameters[@"advertiser_id"],
    "Should not access the advertising ID when disallowed"
  );
}

- (void)testParametersDictionaryWithCachedAdvertiserIDManager
{
  FBSDKSettings.sharedSettings.shouldUseCachedValuesForExpensiveMetadata = YES;

  self.appEventsConfigurationProvider.stubbedConfiguration = [SampleAppEventsConfigurations createWithAdvertiserIDCollectionEnabled:YES];
  FBSDKAppEventsUtility.shared.appEventsConfigurationProvider = self.appEventsConfigurationProvider;

  NSString *identifier = @"68753A44-4D6F-1226-9C60-0050E4C00067";
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:identifier];
  TestASIdentifierManager *identifierManager = [TestASIdentifierManager new];
  identifierManager.stubbedAdvertisingIdentifier = uuid;
  FBSDKAppEventsUtility.cachedAdvertiserIdentifierManager = identifierManager;
  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertEqualObjects(@"event", parameters[@"event"]);
  XCTAssertEqualObjects(
    parameters[@"advertiser_id"],
    @"68753A44-4D6F-1226-9C60-0050E4C00067",
    "Should use the advertiser ID from the cached advertiser identifier manager"
  );
}

- (void)testActivityParametersWithNonEmptyLimitedDataProcessingOptions
{
  [FBSDKSettings.sharedSettings setDataProcessingOptions:@[@"LDU"] country:100 state:1];
  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:NO
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertEqualObjects(@"[\"LDU\"]", parameters[@"data_processing_options"]);
  XCTAssertTrue(
    [(NSNumber *)parameters[@"data_processing_options_country"] isEqualToNumber:[NSNumber numberWithInt:100]],
    "Should use the data processing options from the settings"
  );
  XCTAssertTrue(
    [(NSNumber *)parameters[@"data_processing_options_state"] isEqualToNumber:[NSNumber numberWithInt:1]],
    "Should use the data processing options from the settings"
  );
}

- (void)testActivityParametersWithEmptyLimitedDataProcessingOptions
{
  FBSDKSettings.sharedSettings.dataProcessingOptions = @[];
  NSDictionary<NSString *, id> *parameters = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                               shouldAccessAdvertisingID:YES
                                                                                                  userID:nil
                                                                                                userData:nil];
  XCTAssertEqualObjects(@"[]", parameters[@"data_processing_options"]);
  XCTAssertTrue([(NSNumber *)parameters[@"data_processing_options_country"] isEqualToNumber:[NSNumber numberWithInt:0]]);
  XCTAssertTrue([(NSNumber *)parameters[@"data_processing_options_state"] isEqualToNumber:[NSNumber numberWithInt:0]]);
}

- (void)testLogImplicitEventsExists
{
  Class FBSDKAppEventsClass = NSClassFromString(@"FBSDKAppEvents");
  SEL logEventSelector = NSSelectorFromString(@"logImplicitEvent:valueToSum:parameters:accessToken:");
  XCTAssertTrue([FBSDKAppEventsClass respondsToSelector:logEventSelector]);
}

- (void)testGetAdvertiserIDWithCollectionEnabled
{
  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithAdvertiserIDCollectionEnabled:YES];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertNotNil(
    [FBSDKAppEventsUtility.shared advertiserID],
    "Advertiser id should not be nil when collection is enabled"
  );
}

- (void)testGetAdvertiserIDWithCollectionDisabled
{
  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:NO
                                                                                  eventCollectionEnabled:YES];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertNil(
    [FBSDKAppEventsUtility.shared advertiserID],
    "Should not be able to get an advertiser ID when collection is explicitly disabled"
  );
}

// | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
// | Allowed             | N/A                | N/A                 | YES                    | NO       |
- (void)testShouldDropAppEventWithSettingsATEAllowedEventCollectionEnabled
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:YES];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertFalse(
    [FBSDKAppEventsUtility shouldDropAppEvent],
    "Should not drop events"
  );
}

// | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
// | Allowed             | N/A                | N/A                 | NO                     | NO       |
- (void)testShouldDropAppEventWithSettingsATEAllowedEventCollectionDisabled
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:NO];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertFalse(
    [FBSDKAppEventsUtility shouldDropAppEvent],
    "Should not drop events"
  );
}

// | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
// | Unspecified         | N/A                | N/A                 | YES                    | NO       |
- (void)testShouldDropAppEventWithSettingsATEUnspecifiedEventCollectionEnabled
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingUnspecified;

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:YES];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertFalse(
    [FBSDKAppEventsUtility shouldDropAppEvent],
    "Should not drop events"
  );
}

// | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
// | Unspecified         | N/A                | N/A                 | NO                     | NO       |
- (void)testShouldDropAppEventWithSettingsATEUnspecifiedEventCollectionDisabled
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:NO];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertFalse(
    [FBSDKAppEventsUtility shouldDropAppEvent],
    "Should not drop events"
  );
}

// | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
// | Disallowed          | N/A                | N/A                 | YES                    | NO       |
- (void)testShouldDropAppEventWithSettingsATEDisallowedEventCollectionEnabled
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingDisallowed;

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:YES];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertFalse(
    [FBSDKAppEventsUtility shouldDropAppEvent],
    "Should not drop events"
  );
}

// | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
// | Disallowed          | N/A                | N/A                 | NO                     | YES      |
- (void)testShouldDropAppEventWithSettingsATEDisallowedEventCollectionDisabled
{
  FBSDKSettings.advertiserTrackingStatus = FBSDKAdvertisingTrackingDisallowed;

  FBSDKAppEventsConfiguration *configuration = [SampleAppEventsConfigurations createWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                                                           advertiserIDCollectionEnabled:YES
                                                                                  eventCollectionEnabled:NO];
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  XCTAssertTrue(
    [FBSDKAppEventsUtility shouldDropAppEvent],
    "Should drop events when tracking is disallowed and event collection is disabled"
  );
}

- (void)testAdvertiserTrackingEnabledInAppEventPayload
{
  FBSDKAppEventsConfiguration *configuration = [[FBSDKAppEventsConfiguration alloc] initWithJSON:@{}];

  NSArray<NSNumber *> *statusList = @[@(FBSDKAdvertisingTrackingAllowed), @(FBSDKAdvertisingTrackingDisallowed), @(FBSDKAdvertisingTrackingUnspecified)];
  for (NSNumber *defaultATEStatus in statusList) {
    configuration.defaultATEStatus = defaultATEStatus.unsignedIntegerValue;
    for (NSNumber *status in statusList) {
      self.appEventsConfigurationProvider.stubbedConfiguration = configuration;
      [FBSDKSettings.sharedSettings reset];
      [FBSDKSettings configureWithStore:[UserDefaultsSpy new]
         appEventsConfigurationProvider:self.appEventsConfigurationProvider
                 infoDictionaryProvider:[TestBundle new]
                            eventLogger:[TestEventLogger new]];

      if ([status unsignedIntegerValue] != FBSDKAdvertisingTrackingUnspecified) {
        [FBSDKSettings setAdvertiserTrackingStatus:[status unsignedIntegerValue]];
      }
      NSDictionary<NSString *, id> *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                             shouldAccessAdvertisingID:YES
                                                                                                userID:nil
                                                                                              userData:nil];
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

  self.appEventsConfigurationProvider.stubbedConfiguration = [SampleAppEventsConfigurations createWithEventCollectionEnabled:YES];

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
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an app id or client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithClientToken
{
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an app id"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithoutClientToken
{
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = SampleAccessTokens.validToken.appID;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without a client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithClientToken
{
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = @"abc";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertEqualObjects(
    tokenString,
    @"abc|toktok",
    "Should provide a token string with the app id and client token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithClientToken
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithoutClientToken
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithoutClientToken
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token when "
    "the app id on the token does not match the app id in settings"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientToken
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:nil];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the current access token when "
    "the app id on the token does not match the app id in settings"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an access token, app id, or client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without an access token or app id"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = SampleAccessTokens.validToken.appID;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string without a client token"
  );
}

- (void)testTokenStringWithoutAccessTokenWithAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKSettings.sharedSettings.appID = SampleAccessTokens.validToken.appID;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string with the logging app id and client token"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = nil;
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppID
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:@"789"];
  XCTAssertNil(
    tokenString,
    "Should not provide a token string when the logging override and access token app ids are mismatched"
  );
}

- (void)testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppIDMatching
{
  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
  FBSDKSettings.sharedSettings.appID = @"456";
  FBSDKSettings.sharedSettings.clientToken = @"toktok";
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:nil
                                                loggingOverrideAppID:SampleAccessTokens.validToken.appID];
  XCTAssertEqualObjects(
    tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should provide the token string stored on the access token when the access token's app id matches the logging override"
  );
}

@end
