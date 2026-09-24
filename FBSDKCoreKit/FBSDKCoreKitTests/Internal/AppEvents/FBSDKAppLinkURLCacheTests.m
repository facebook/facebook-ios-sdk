/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <XCTest/XCTest.h>

#import "FBSDKAppLinkURLCache+Testing.h"
#import "FBSDKCoreKitTests-Swift.h"

@interface FBSDKAppLinkURLCacheTests : XCTestCase

@property (nonatomic) NSUserDefaults *dataStore;

@end

@implementation FBSDKAppLinkURLCacheTests

- (void)setUp
{
  [super setUp];
  // An isolated suite keeps the tests from reading or writing the app's standard defaults.
  self.dataStore = [[NSUserDefaults alloc] initWithSuiteName:NSStringFromClass(self.class)];
  FBSDKAppLinkURLCache.shared.dataStore = self.dataStore;
  // Required: metadata collection is off by default, so without this every write below is
  // suppressed and these tests pass vacuously.
  FBSDKAppLinkURLCache.shared.settings = [TestSettingsFactory settingsWithMetaDataCollectionEnabled];
}

- (void)tearDown
{
  [FBSDKAppLinkURLCache.shared reset];
  [self.dataStore removePersistentDomainForName:NSStringFromClass(self.class)];
  self.dataStore = nil;
  [super tearDown];
}

- (void)testCachingInboundAndOutboundURLsIndependently
{
  [FBSDKAppLinkURLCache.shared cacheInboundURL:[NSURL URLWithString:@"myapp://in?a=1"]];
  [FBSDKAppLinkURLCache.shared cacheOutboundURL:[NSURL URLWithString:@"https://example.com/out"]];

  XCTAssertEqualObjects(
    FBSDKAppLinkURLCache.shared.inboundURL,
    @"myapp://in?a=1",
    "Should store the full inbound URL string"
  );
  XCTAssertEqualObjects(
    FBSDKAppLinkURLCache.shared.outboundURL,
    @"https://example.com/out",
    "Should store the full outbound URL string, without clobbering the inbound one"
  );
}

- (void)testCachingUsesStableUserDefaultsKeys
{
  [FBSDKAppLinkURLCache.shared cacheInboundURL:[NSURL URLWithString:@"myapp://in"]];
  [FBSDKAppLinkURLCache.shared cacheOutboundURL:[NSURL URLWithString:@"myapp://out"]];

  // The keys are part of the on-disk contract; changing them silently drops cached attribution.
  XCTAssertEqualObjects(
    [self.dataStore fb_stringForKey:@"com.facebook.sdk:inbound_url"],
    @"myapp://in",
    "Should persist the inbound URL under com.facebook.sdk:inbound_url"
  );
  XCTAssertEqualObjects(
    [self.dataStore fb_stringForKey:@"com.facebook.sdk:outbound_url"],
    @"myapp://out",
    "Should persist the outbound URL under com.facebook.sdk:outbound_url"
  );
}

- (void)testCachingLatestURLOverwritesPrevious
{
  [FBSDKAppLinkURLCache.shared cacheInboundURL:[NSURL URLWithString:@"myapp://first"]];
  [FBSDKAppLinkURLCache.shared cacheInboundURL:[NSURL URLWithString:@"myapp://second"]];

  XCTAssertEqualObjects(
    FBSDKAppLinkURLCache.shared.inboundURL,
    @"myapp://second",
    "Should keep only the most recent inbound URL"
  );
}

- (void)testCachingNilURLKeepsPreviousValue
{
  [FBSDKAppLinkURLCache.shared cacheInboundURL:[NSURL URLWithString:@"myapp://in"]];
  [FBSDKAppLinkURLCache.shared cacheInboundURL:nil];

  // A universal link with no webpageURL must not erase a previously attributed deep link.
  XCTAssertEqualObjects(
    FBSDKAppLinkURLCache.shared.inboundURL,
    @"myapp://in",
    "Should ignore a nil URL rather than clearing the cached value"
  );
}

- (void)testReadingURLsBeforeAnythingIsCached
{
  XCTAssertNil(
    FBSDKAppLinkURLCache.shared.inboundURL,
    "Should have no inbound URL before one is cached"
  );
  XCTAssertNil(
    FBSDKAppLinkURLCache.shared.outboundURL,
    "Should have no outbound URL before one is cached"
  );
}

@end
