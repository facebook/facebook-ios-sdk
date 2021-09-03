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

#if !TARGET_OS_TV

 #import "FBSDKConversionValueUpdating.h"
 #import "FBSDKCoreKitTests-Swift.h"
 #import "FBSDKSKAdNetworkConversionConfiguration.h"
 #import "FBSDKSKAdNetworkReporter.h"
 #import "FBSDKSKAdNetworkReporter+Internal.h"
 #import "FBSDKSettings+Internal.h"

static NSString *const FBSDKSettingsInstallTimestamp = @"com.facebook.sdk:FBSDKSettingsInstallTimestamp";
static NSString *const FBSDKSKAdNetworkReporterKey = @"com.facebook.sdk:FBSDKSKAdNetworkReporter";

typedef void (^FBSDKSKAdNetworkReporterBlock)(void);
@interface FBSDKSKAdNetworkReporter ()
@property (nonnull, nonatomic, readonly) id<FBSDKGraphRequestProviding> requestProvider;
@property (nonnull, nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nonnull, nonatomic, readonly) Class<FBSDKConversionValueUpdating> conversionValueUpdatable;

- (void)setConfiguration:(FBSDKSKAdNetworkConversionConfiguration *)configuration;
- (void)_loadReportData;
- (void)_recordAndUpdateEvent:(NSString *)event
                     currency:(nullable NSString *)currency
                        value:(nullable NSNumber *)value;
- (void)_updateConversionValue:(NSInteger)value;

- (void)setSKAdNetworkReportEnabled:(BOOL)enabled;

- (void)_loadConfigurationWithBlock:(FBSDKSKAdNetworkReporterBlock)block;
- (void)configureWithRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
                               store:(id<FBSDKDataPersisting>)store;

@end

@interface FBSDKSKAdNetworkReporterTests : XCTestCase
@property (nonnull, nonatomic) FBSDKSKAdNetworkReporter *skAdNetworkReporter;
@property (nonatomic) UserDefaultsSpy *userDefaultsSpy;
@property (nonatomic) TestGraphRequestFactory *requestProvider;
@property (nonatomic) FBSDKSKAdNetworkConversionConfiguration *defaultConfiguration;
@end

@implementation FBSDKSKAdNetworkReporterTests

- (void)setUp
{
  [super setUp];
  [TestConversionValueUpdating reset];
  self.userDefaultsSpy = [UserDefaultsSpy new];
  self.requestProvider = [TestGraphRequestFactory new];

  NSDictionary *json = @{
    @"data" : @[@{
                  @"timer_buckets" : @1,
                  @"timer_interval" : @1000,
                  @"cutoff_time" : @1,
                  @"default_currency" : @"usd",
                  @"conversion_value_rules" : @[],
    }]
  };
  self.defaultConfiguration = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:json];

  self.skAdNetworkReporter = [[FBSDKSKAdNetworkReporter alloc] initWithRequestProvider:self.requestProvider store:self.userDefaultsSpy conversionValueUpdatable:TestConversionValueUpdating.class];
  [self.skAdNetworkReporter _loadReportData];
  [self.skAdNetworkReporter setSKAdNetworkReportEnabled:YES];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testEnable
{
  [self.skAdNetworkReporter setSKAdNetworkReportEnabled:NO];
  [self.skAdNetworkReporter enable];

  XCTAssertTrue(
    self.skAdNetworkReporter.isSKAdNetworkReportEnabled,
    "SKAdNetwork report should be enabled"
  );
}

- (void)testLoadReportData
{
  NSMutableSet<NSString *> *recordedEvents = [NSMutableSet setWithObject:@"fb_mobile_puchase"];
  NSMutableDictionary<NSString *, NSMutableDictionary *> *recordedValues = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                              @"fb_mobile_purchase" : [NSMutableDictionary dictionaryWithDictionary:@{@"USD" : @(10)}]
                                                                            }];
  NSInteger conversionValue = 10;
  NSDate *timestamp = [NSDate date];
  [self saveEvents:recordedEvents values:recordedValues conversionValue:conversionValue timestamp:timestamp];

  [self.skAdNetworkReporter _loadReportData];
  XCTAssertEqualObjects(
    recordedEvents,
    self.skAdNetworkReporter.recordedEvents,
    @"Should load the expected recorded events"
  );
  XCTAssertEqualObjects(
    recordedValues,
    self.skAdNetworkReporter.recordedValues,
    @"Should load the expected recorded values"
  );
  XCTAssertEqual(
    conversionValue,
    self.skAdNetworkReporter.conversionValue,
    @"Should load the expected conversion value"
  );
  XCTAssertEqual(
    timestamp.timeIntervalSince1970,
    self.skAdNetworkReporter.timestamp.timeIntervalSince1970,
    @"Should load the expected timestamp"
  );
}

- (void)testLoadConfigurationWithValidCache
{
  self.skAdNetworkReporter.serialQueue = dispatch_queue_create(self.name.UTF8String, DISPATCH_QUEUE_SERIAL);
  self.skAdNetworkReporter.completionBlocks = [NSMutableArray new];
  self.skAdNetworkReporter.configRefreshTimestamp = [NSDate date];
  [self.userDefaultsSpy setObject:SampleSKAdNetworkConversionConfiguration.configJson forKey:@"com.facebook.sdk:FBSDKSKAdNetworkConversionConfiguration"];

  __block int count = 0;
  [self.skAdNetworkReporter _loadConfigurationWithBlock:^{
    count += 1;
  }];
  XCTAssertEqual(count, 1, @"Should expect the execution block to be called once");
  XCTAssertEqual(self.requestProvider.capturedRequests.count, 0, "Should not have graph request with valid cache");
}

- (void)testLoadConfigurationWithoutValidCacheAndWithoutNetworkError
{
  self.skAdNetworkReporter.config = nil;
  self.skAdNetworkReporter.serialQueue = dispatch_queue_create(self.name.UTF8String, DISPATCH_QUEUE_SERIAL);
  self.skAdNetworkReporter.completionBlocks = [NSMutableArray new];

  __block int count = 0;
  [self.skAdNetworkReporter _loadConfigurationWithBlock:^{
    count += 1;
  }];
  TestGraphRequest *request = self.requestProvider.capturedRequests.firstObject;
  request.capturedCompletionHandler(nil, SampleSKAdNetworkConversionConfiguration.configJson, nil);
  XCTAssertEqual(count, 1, @"Should expect the execution block to be called once");
  XCTAssertEqual(self.requestProvider.capturedRequests.count, 1, "Should have graph request without valid cache");
  XCTAssertTrue(
    [self.requestProvider.capturedGraphPath containsString:@"ios_skadnetwork_conversion_config"],
    "Should have graph request for config without valid cache"
  );
  XCTAssertNotNil(self.skAdNetworkReporter.config, @"Should have expected config");
}

- (void)testLoadConfigurationWithoutValidCacheAndWithNetworkError
{
  self.skAdNetworkReporter.config = nil;
  self.skAdNetworkReporter.serialQueue = dispatch_queue_create(self.name.UTF8String, DISPATCH_QUEUE_SERIAL);
  self.skAdNetworkReporter.completionBlocks = [NSMutableArray new];

  __block int count = 0;
  [self.skAdNetworkReporter _loadConfigurationWithBlock:^{
    count += 1;
  }];
  TestGraphRequest *request = self.requestProvider.capturedRequests.firstObject;
  request.capturedCompletionHandler(nil, SampleSKAdNetworkConversionConfiguration.configJson, [NSError errorWithDomain:@"test" code:0 userInfo:nil]);
  XCTAssertEqual(count, 0, @"Should not expect the execution block to be called");
  XCTAssertEqual(self.requestProvider.capturedRequests.count, 1, "Should have graph request without valid cache");
  XCTAssertTrue(
    [self.requestProvider.capturedGraphPath containsString:@"ios_skadnetwork_conversion_config"],
    "Should have graph request for config without valid cache"
  );
  XCTAssertNil(self.skAdNetworkReporter.config, @"Should not have config with network error");
}

- (void)testShouldCutoffWithoutTimestampWithoutCutoffTime
{
  XCTAssertTrue([self.skAdNetworkReporter shouldCutoff], "Should cut off reporting when there is no install timestamp or cutoff time");
}

- (void)testShouldCutoffWithoutTimestampWithCutoffTime
{
  [self.skAdNetworkReporter setConfiguration:self.defaultConfiguration];

  XCTAssertFalse([self.skAdNetworkReporter shouldCutoff], "Should not cut off reporting when there is no install timestamp");
}

- (void)testShouldCutoffWithTimestampWithoutCutoffTime
{
  [self.userDefaultsSpy setObject:NSDate.distantPast forKey:FBSDKSettingsInstallTimestamp];
  XCTAssertTrue(
    [self.skAdNetworkReporter shouldCutoff],
    "Should cut off reporting when when the timestamp is earlier than the current date and there's no cutoff date provided"
  );
  [self.userDefaultsSpy setObject:NSDate.distantFuture forKey:FBSDKSettingsInstallTimestamp];
  XCTAssertTrue(
    [self.skAdNetworkReporter shouldCutoff],
    "Should cut off reporting when the timestamp is later than the current date and there's no cutoff date provided"
  );
}

- (void)testShouldCutoffWhenTimestampEarlierThanCutoffTime
{
  [self.skAdNetworkReporter setConfiguration:self.defaultConfiguration];
  [self.userDefaultsSpy setObject:NSDate.distantPast forKey:FBSDKSettingsInstallTimestamp];

  XCTAssertTrue(
    [self.skAdNetworkReporter shouldCutoff],
    "Should cut off reporting when the install timestamp is one day before the cutoff date"
  );
}

- (void)testShouldCutoffWhenTimestampLaterThanCutoffTime
{
  [self.skAdNetworkReporter setConfiguration:self.defaultConfiguration];
  [self.userDefaultsSpy setObject:NSDate.distantFuture forKey:FBSDKSettingsInstallTimestamp];

  XCTAssertFalse(
    [self.skAdNetworkReporter shouldCutoff],
    "Should not cut off reporting when the install timestamp is more than one day later than the cutoff date"
  );
}

- (void)testShouldCutoff
{
  [self.skAdNetworkReporter setConfiguration:self.defaultConfiguration];

  // Case 1: refresh install
  [FBSDKSettings.sharedSettings recordInstall];
  XCTAssertFalse([self.skAdNetworkReporter shouldCutoff]);

  // Case 2: timestamp is already expired
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *addComponents = [NSDateComponents new];
  addComponents.day = -2;
  NSDate *expiredDate = [calendar dateByAddingComponents:addComponents toDate:[NSDate date] options:0];
  [self.userDefaultsSpy setObject:expiredDate forKey:FBSDKSettingsInstallTimestamp];
  XCTAssertTrue([self.skAdNetworkReporter shouldCutoff]);

  [self.userDefaultsSpy removeObjectForKey:FBSDKSettingsInstallTimestamp];
}

- (void)testCutoffWhenTimeBucketIsAvailable
{
  if (@available(iOS 14, *)) {
    [self.skAdNetworkReporter setConfiguration:self.defaultConfiguration];
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *addComponents = [NSDateComponents new];
    addComponents.day = -2;
    NSDate *expiredDate = [calendar dateByAddingComponents:addComponents toDate:today options:0];
    [self.userDefaultsSpy setObject:expiredDate forKey:FBSDKSettingsInstallTimestamp];

    XCTAssertTrue([self.skAdNetworkReporter shouldCutoff]);
    [self.skAdNetworkReporter checkAndRevokeTimer];
    XCTAssertNil([self.userDefaultsSpy objectForKey:FBSDKSKAdNetworkReporterKey]);
    XCTAssertFalse([TestConversionValueUpdating wasUpdateVersionValueCalled]);
    [self.userDefaultsSpy removeObjectForKey:FBSDKSettingsInstallTimestamp];
  }
}

- (void)testIsReportingEventWithConfig
{
  [self.skAdNetworkReporter setConfiguration:
   [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:SampleSKAdNetworkConversionConfiguration.configJson]];

  XCTAssertTrue(
    [self.skAdNetworkReporter isReportingEvent:@"fb_test"],
    @"Should expect to be true for event in the config"
  );
  XCTAssertFalse(
    [self.skAdNetworkReporter isReportingEvent:@"test"],
    @"Should expect to be false for event not in the config"
  );
}

- (void)testIsReportingEventWithoutConfig
{
  [self.skAdNetworkReporter setConfiguration:nil];

  XCTAssertFalse(
    [self.skAdNetworkReporter isReportingEvent:@"fb_test"],
    @"Should not be considered to be reporting an event when there is no configuration"
  );
}

- (void)testUpdateConversionValue
{
  [self.skAdNetworkReporter setConfiguration:self.defaultConfiguration];
  [self.skAdNetworkReporter _updateConversionValue:2];
  XCTAssertTrue(
    [TestConversionValueUpdating wasUpdateVersionValueCalled],
    "Should call updateConversionValue when not cutoff"
  );
}

- (void)testRecord
{
  if (@available(iOS 14, *)) {
    FBSDKSKAdNetworkConversionConfiguration *config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:SampleSKAdNetworkConversionConfiguration.configJson];
    [self.skAdNetworkReporter setConfiguration:config];
    [self.skAdNetworkReporter _recordAndUpdateEvent:@"fb_test" currency:nil value:nil];
    [self.skAdNetworkReporter _recordAndUpdateEvent:@"fb_mobile_purchase" currency:@"USD" value:@100];
    [self.skAdNetworkReporter _recordAndUpdateEvent:@"fb_mobile_purchase" currency:@"USD" value:@201];
    [self.skAdNetworkReporter _recordAndUpdateEvent:@"test" currency:nil value:nil];
    NSData *cache = [self.userDefaultsSpy objectForKey:FBSDKSKAdNetworkReporterKey];
    XCTAssertNotNil(cache);
    // cannot adopt NSKeyedUnarchiver.unarchivedDictionaryWithKeysOfClasses::: due to nested collections
    NSDictionary<NSString *, id> *data = [FBSDKTypeUtility dictionaryValue:[NSKeyedUnarchiver
                                                                            unarchivedObjectOfClasses:[NSSet setWithArray:
                                                                                                       @[NSDictionary.class,
                                                                                                         NSString.class,
                                                                                                         NSNumber.class,
                                                                                                         NSDate.class,
                                                                                                         NSSet.class]]
                                                                            fromData:cache
                                                                            error:nil]];
    NSMutableSet<NSString *> *recordedEvents = [FBSDKTypeUtility dictionary:data objectForKey:@"recorded_events" ofType:NSMutableSet.class];
    NSSet<NSString *> *expectedEvents = [NSSet setWithArray:@[@"fb_test", @"fb_mobile_purchase"]];
    XCTAssertTrue([expectedEvents isEqualToSet:recordedEvents]);
    NSMutableDictionary<NSString *, id> *recordedValues = [FBSDKTypeUtility dictionary:data objectForKey:@"recorded_values" ofType:NSMutableDictionary.class];
    NSDictionary<NSString *, id> *expectedValues = @{
      @"fb_mobile_purchase" : @{
        @"USD" : @301
      }
    };
    XCTAssertTrue([expectedValues isEqualToDictionary:recordedValues]);
  }
}

- (void)testInitializeWithDependencies
{
  id<FBSDKGraphRequestProviding> requestProvider = [FBSDKGraphRequestFactory new];
  id<FBSDKDataPersisting> store = [UserDefaultsSpy new];
  FBSDKSKAdNetworkReporter *reporter = [[FBSDKSKAdNetworkReporter alloc] initWithRequestProvider:requestProvider
                                                                                           store:store
                                                                        conversionValueUpdatable:TestConversionValueUpdating.class];

  XCTAssertEqualObjects(
    requestProvider,
    reporter.requestProvider,
    "Should be able to configure a reporter with a request provider"
  );
  XCTAssertEqualObjects(
    store,
    reporter.store,
    "Should be able to configure a reporter with a persistent data store"
  );
  XCTAssertEqualObjects(
    TestConversionValueUpdating.class,
    reporter.conversionValueUpdatable,
    "Should be able to configure a reporter with a Conversion Value Updater"
  );
}

- (void)saveEvents:(NSMutableSet *)events
            values:(NSMutableDictionary *)values
   conversionValue:(NSInteger)conversionValue
         timestamp:(NSDate *)timestamp
{
  NSMutableDictionary<NSString *, id> *reportData = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:reportData setObject:@(conversionValue) forKey:@"conversion_value"];
  [FBSDKTypeUtility dictionary:reportData setObject:timestamp forKey:@"timestamp"];
  [FBSDKTypeUtility dictionary:reportData setObject:events forKey:@"recorded_events"];
  [FBSDKTypeUtility dictionary:reportData setObject:values forKey:@"recorded_values"];
  NSData *cache = [NSKeyedArchiver archivedDataWithRootObject:reportData];
  [self.userDefaultsSpy setObject:cache forKey:@"com.facebook.sdk:FBSDKSKAdNetworkReporter"];
}

@end

#endif
