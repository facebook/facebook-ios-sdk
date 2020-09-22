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

 #import <StoreKit/StoreKit.h>

 #import "FBSDKSKAdNetworkConversionConfiguration.h"
 #import "FBSDKSKAdNetworkReporter.h"
 #import "FBSDKSettings+Internal.h"
 #import "FBSDKTestCase.h"
 #import "UserDefaultsSpy.h"

static NSString *const FBSDKSettingsInstallTimestamp = @"com.facebook.sdk:FBSDKSettingsInstallTimestamp";
static NSString *const FBSDKSKAdNetworkReporterKey = @"com.facebook.sdk:FBSDKSKAdNetworkReporter";

@interface FBSDKSKAdNetworkReporter ()

+ (void)setConfiguration:(FBSDKSKAdNetworkConversionConfiguration *)configuration;
+ (void)_loadReportData;
+ (BOOL)_shouldCutoff;
+ (void)_recordAndUpdateEvent:(NSString *)event
                     currency:(nullable NSString *)currency
                        value:(nullable NSNumber *)value;
+ (void)_updateConversionValue:(NSInteger)value;

+ (void)setSKAdNetworkReportEnabled:(BOOL)enabled;

@end

@interface FBSDKSKAdNetworkReporterTests : FBSDKTestCase

@end

@implementation FBSDKSKAdNetworkReporterTests
{
  UserDefaultsSpy *userDefaultsSpy;
  FBSDKSKAdNetworkConversionConfiguration *defaultConfiguration;
}

- (void)setUp
{
  [super setUp];

  userDefaultsSpy = [UserDefaultsSpy new];
  [self stubUserDefaultsWith:userDefaultsSpy];

  NSDictionary *json = @{
    @"data" : @[@{
                  @"timer_buckets" : @(1),
                  @"timer_interval" : @(1000),
                  @"cutoff_time" : @(1),
                  @"default_currency" : @"usd",
                  @"conversion_value_rules" : @[],
    }]
  };
  defaultConfiguration = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:json];

  [FBSDKSKAdNetworkReporter _loadReportData];
  [FBSDKSKAdNetworkReporter setSKAdNetworkReportEnabled:YES];

  [self stubLoadingAdNetworkReporterConfiguration];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testShouldCutoffWithoutTimestampWithoutCutoffTime
{
  XCTAssertTrue([FBSDKSKAdNetworkReporter _shouldCutoff], "Should cut off reporting when there is no install timestamp or cutoff time");
}

- (void)testShouldCutoffWithoutTimestampWithCutoffTime
{
  [FBSDKSKAdNetworkReporter setConfiguration:defaultConfiguration];

  XCTAssertFalse([FBSDKSKAdNetworkReporter _shouldCutoff], "Should not cut off reporting when there is no install timestamp");
}

- (void)testShouldCutoffWithTimestampWithoutCutoffTime
{
  [userDefaultsSpy setObject:NSDate.distantPast forKey:FBSDKSettingsInstallTimestamp];
  XCTAssertTrue(
    [FBSDKSKAdNetworkReporter _shouldCutoff],
    "Should cut off reporting when when the timestamp is earlier than the current date and there's no cutoff date provided"
  );
  [userDefaultsSpy setObject:NSDate.distantFuture forKey:FBSDKSettingsInstallTimestamp];
  XCTAssertTrue(
    [FBSDKSKAdNetworkReporter _shouldCutoff],
    "Should cut off reporting when the timestamp is later than the current date and there's no cutoff date provided"
  );
}

- (void)testShouldCutoffWhenTimestampEarlierThanCutoffTime
{
  [FBSDKSKAdNetworkReporter setConfiguration:defaultConfiguration];
  [userDefaultsSpy setObject:NSDate.distantPast forKey:FBSDKSettingsInstallTimestamp];

  XCTAssertTrue(
    [FBSDKSKAdNetworkReporter _shouldCutoff],
    "Should cut off reporting when the install timestamp is one day before the cutoff date"
  );
}

- (void)testShouldCutoffWhenTimestampLaterThanCutoffTime
{
  [FBSDKSKAdNetworkReporter setConfiguration:defaultConfiguration];
  [userDefaultsSpy setObject:NSDate.distantFuture forKey:FBSDKSettingsInstallTimestamp];

  XCTAssertFalse(
    [FBSDKSKAdNetworkReporter _shouldCutoff],
    "Should not cut off reporting when the install timestamp is more than one day later than the cutoff date"
  );
}

- (void)testShouldCutoff
{
  [FBSDKSKAdNetworkReporter setConfiguration:defaultConfiguration];

  // Case 1: refresh install
  [FBSDKSettings recordInstall];
  XCTAssertFalse([FBSDKSKAdNetworkReporter _shouldCutoff]);

  // Case 2: timestamp is already expired
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *addComponents = [NSDateComponents new];
  addComponents.day = -2;
  NSDate *expiredDate = [calendar dateByAddingComponents:addComponents toDate:[NSDate date] options:0];
  [[NSUserDefaults standardUserDefaults] setObject:expiredDate forKey:FBSDKSettingsInstallTimestamp];
  XCTAssertTrue([FBSDKSKAdNetworkReporter _shouldCutoff]);

  [[NSUserDefaults standardUserDefaults] removeObjectForKey:FBSDKSettingsInstallTimestamp];
}

- (void)testCutoffWhenTimeBucketIsAvailable
{
  if (@available(iOS 14, *)) {
    id mock = OCMClassMock([SKAdNetwork class]);
    [FBSDKSKAdNetworkReporter setConfiguration:defaultConfiguration];
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *addComponents = [NSDateComponents new];
    addComponents.day = -2;
    NSDate *expiredDate = [calendar dateByAddingComponents:addComponents toDate:today options:0];
    [userDefaultsSpy setObject:expiredDate forKey:FBSDKSettingsInstallTimestamp];

    XCTAssertTrue([FBSDKSKAdNetworkReporter _shouldCutoff]);
    [FBSDKSKAdNetworkReporter checkAndRevokeTimer];
    XCTAssertNil([userDefaultsSpy objectForKey:FBSDKSKAdNetworkReporterKey]);

    [mock reject];

    [userDefaultsSpy removeObjectForKey:FBSDKSettingsInstallTimestamp];
  }
}

- (void)testRecord
{
  if (@available(iOS 14, *)) {
    NSDictionary<NSString *, id> *json = @{
      @"data" : @[@{
                    @"timer_buckets" : @(1),
                    @"timer_interval" : @(1000),
                    @"cutoff_time" : @(1),
                    @"default_currency" : @"USD",
                    @"conversion_value_rules" : @[
                      @{
                        @"conversion_value" : @(2),
                        @"events" : @[
                          @{
                            @"event_name" : @"fb_test",
                          }
                        ],
                    }],
      }]
    };
    FBSDKSKAdNetworkConversionConfiguration *config = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:json];
    [FBSDKSKAdNetworkReporter setConfiguration:config];
    [FBSDKSKAdNetworkReporter _recordAndUpdateEvent:@"fb_test" currency:nil value:nil];
    [FBSDKSKAdNetworkReporter _recordAndUpdateEvent:@"fb_mobile_purchase" currency:@"USD" value:@(100)];
    [FBSDKSKAdNetworkReporter _recordAndUpdateEvent:@"fb_mobile_purchase" currency:@"USD" value:@(201)];
    [FBSDKSKAdNetworkReporter _recordAndUpdateEvent:@"test" currency:nil value:nil];
    NSData *cache = [[NSUserDefaults standardUserDefaults] objectForKey:FBSDKSKAdNetworkReporterKey];
    XCTAssertNotNil(cache);
    NSDictionary<NSString *, id> *data = [FBSDKTypeUtility dictionaryValue:[NSKeyedUnarchiver unarchiveObjectWithData:cache]];
    NSMutableSet<NSString *> *recordedEvents = [FBSDKTypeUtility dictionary:data objectForKey:@"recorded_events" ofType:NSMutableSet.class];
    NSSet<NSString *> *expectedEvents = [NSSet setWithArray:@[@"fb_test", @"fb_mobile_purchase"]];
    XCTAssertTrue([expectedEvents isEqualToSet:recordedEvents]);
    NSMutableDictionary<NSString *, id> *recordedValues = [FBSDKTypeUtility dictionary:data objectForKey:@"recorded_values" ofType:NSMutableDictionary.class];
    NSDictionary<NSString *, id> *expectedValues = @{
      @"fb_mobile_purchase" : @{
        @"USD" : @(301)
      }
    };
    XCTAssertTrue([expectedValues isEqualToDictionary:recordedValues]);
  }
}

@end

#endif
