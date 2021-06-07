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

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKCrashShield.h"
#import "FBSDKFeatureDisabling.h"
#import "FBSDKFeatureManager.h"

@interface FBSDKCrashShield (Testing)

+ (nullable NSString *)_getFeature:(NSArray<NSString *> *)callstack;
+ (nullable NSString *)_getClassName:(NSString *)entry;
+ (void)configureWithSettings:(id<FBSDKSettings>)settings
              requestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
              featureChecking:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking;

+ (void)reset;

+ (FBSDKFeature)featureForString:(NSString *)featureName;

@end

@interface FBSDKCrashShieldTests : XCTestCase

@property (nonatomic) TestSettings *settings;
@property (nonatomic) TestGraphRequestFactory *graphRequestFactory;
@property (nonatomic) TestFeatureManager *featureManager;

@end

@implementation FBSDKCrashShieldTests

typedef FBSDKCrashShield CrashShield;

- (void)setUp
{
  [super setUp];
  [FBSDKCrashShield reset];
  _settings = [TestSettings new];
  _graphRequestFactory = [TestGraphRequestFactory new];
  _featureManager = [TestFeatureManager new];
  [CrashShield configureWithSettings:_settings
                     requestProvider:_graphRequestFactory
                     featureChecking:_featureManager];
}

// MARK: - Get Feature

- (void)testGetFeature
{
  // gated feature in corekit
  NSArray<NSString *> *callstack1 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKMetadataIndexer crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName1 = [FBSDKCrashShield _getFeature:callstack1];
  XCTAssertTrue([featureName1 isEqualToString:@"AAM"]);

  NSArray<NSString *> *callstack2 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKCodelessIndexer crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName2 = [FBSDKCrashShield _getFeature:callstack2];
  XCTAssertTrue([featureName2 isEqualToString:@"CodelessEvents"]);

  NSArray<NSString *> *callstack3 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKRestrictiveDataFilterManager crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName3 = [FBSDKCrashShield _getFeature:callstack3];
  XCTAssertTrue([featureName3 isEqualToString:@"RestrictiveDataFiltering"]);

  NSArray<NSString *> *callstack4 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKErrorReport crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName4 = [FBSDKCrashShield _getFeature:callstack4];
  XCTAssertTrue([featureName4 isEqualToString:@"ErrorReport"]);

  // feature in other kit
  NSArray<NSString *> *callstack5 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKVideoUploader crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName5 = [FBSDKCrashShield _getFeature:callstack5];
  XCTAssertNil(featureName5);
}

- (void)testParsingFeatureFromValidCallstack
{
  NSArray<NSString *> *callstack = @[@"(4 DEV METHODS)",
                                     @"+[FBSDKVideoUploader crash]+84",
                                     @"(22 DEV METHODS)"];
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield _getFeature:[Fuzzer randomizeWithJson:callstack]];
  }
}

- (void)testParsingFeatureFromGarbage
{
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield _getFeature:Fuzzer.random];
  }
}

// MARK: - Get Class Name

- (void)testGetClassName
{
  // class method
  NSString *entry1 = @"+[FBSDKRestrictiveDataFilterManager crash]+84";
  NSString *className1 = [FBSDKCrashShield _getClassName:entry1];
  XCTAssertTrue([className1 isEqualToString:@"FBSDKRestrictiveDataFilterManager"]);

  // instance method
  NSString *entry2 = @"-[FBSDKRestrictiveDataFilterManager crash]+84";
  NSString *className2 = [FBSDKCrashShield _getClassName:entry2];
  XCTAssertTrue([className2 isEqualToString:@"FBSDKRestrictiveDataFilterManager"]);

  // ineligible format
  NSString *entry3 = @"(6 DEV METHODS)";
  NSString *className3 = [FBSDKCrashShield _getClassName:entry3];
  XCTAssertNil(className3);
}

- (void)testParsingClassName
{
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield _getClassName:Fuzzer.random];
  }
}

- (void)testAnalyzingEmptyCrashLogs
{
  // Should not create a graph request for posting a non-existent crash
  [FBSDKCrashShield analyze:@[]];
  XCTAssertNil(
    [self.graphRequestFactory capturedGraphPath],
    "Should not create a graph request for posting a non-existent crash"
  );
}

- (void)testAnalyzingInvalidCrashLogs
{
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield _getClassName:[Fuzzer randomizeWithJson:self.coreKitCrashLogs]];
  }
}

// MARK: - Analyze: Disabling Features

- (void)testDisablingCoreKitFeatureWithDataProcessingRestricted
{
  self.settings.stubbedIsDataProcessingRestricted = YES;
  [FBSDKCrashShield analyze:self.coreKitCrashLogs];

  XCTAssertTrue(
    [self.featureManager disabledFeaturesContains:FBSDKFeatureCodelessEvents],
    "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
  );
}

- (void)testDisablingNonCoreKitFeatureWithDataProcessingRestricted
{
  self.settings.stubbedIsDataProcessingRestricted = YES;
  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];

  XCTAssertFalse(
    [self.featureManager disabledFeaturesContains:FBSDKFeatureCodelessEvents],
    "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
  );
}

- (void)testDisablingCoreKitFeatureWithDataProcessingUnrestricted
{
  self.settings.stubbedIsDataProcessingRestricted = NO;

  [FBSDKCrashShield analyze:self.coreKitCrashLogs];

  XCTAssertTrue(
    [self.featureManager disabledFeaturesContains:FBSDKFeatureCodelessEvents],
    "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
  );
}

- (void)testDisablingNonCoreKitFeatureWithDataProcessingUnrestricted
{
  self.settings.stubbedIsDataProcessingRestricted = NO;
  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];

  XCTAssertFalse(
    [self.featureManager disabledFeaturesContains:FBSDKFeatureCodelessEvents],
    "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
  );
}

- (void)testFeatureForStringWithFeatureNone
{
  NSDictionary<NSString *, NSNumber *> *pairs = @{
    @"" : @(FBSDKFeatureNone),
    @"CoreKit" : @(FBSDKFeatureCore),
    @"AppEvents" : @(FBSDKFeatureAppEvents),
    @"CodelessEvents" : @(FBSDKFeatureCodelessEvents),
    @"RestrictiveDataFiltering" : @(FBSDKFeatureRestrictiveDataFiltering),
    @"AAM" : @(FBSDKFeatureAAM),
    @"PrivacyProtection" : @(FBSDKFeaturePrivacyProtection),
    @"SuggestedEvents" : @(FBSDKFeatureSuggestedEvents),
    @"IntelligentIntegrity" : @(FBSDKFeatureIntelligentIntegrity),
    @"ModelRequest" : @(FBSDKFeatureModelRequest),
    @"EventDeactivation" : @(FBSDKFeatureEventDeactivation),
    @"SKAdNetwork" : @(FBSDKFeatureSKAdNetwork),
    @"SKAdNetworkConversionValue" : @(FBSDKFeatureSKAdNetworkConversionValue),
    @"Instrument" : @(FBSDKFeatureInstrument),
    @"CrashReport" : @(FBSDKFeatureCrashReport),
    @"CrashShield" : @(FBSDKFeatureCrashShield),
    @"ErrorReport" : @(FBSDKFeatureErrorReport),
    @"ATELogging" : @(FBSDKFeatureATELogging),
    @"AEM" : @(FBSDKFeatureAEM),
    @"LoginKit" : @(FBSDKFeatureLogin),
    @"ShareKit" : @(FBSDKFeatureShare),
    @"GamingServicesKit" : @(FBSDKFeatureGamingServices),
  };

  for (id key in pairs) {
    XCTAssertEqual(
      [FBSDKCrashShield featureForString:key],
      [pairs objectForKey:key].intValue
    );
  }
}

// MARK: - Analyze: Posting Crash Logs

- (void)testPostingCoreKitCrashLogsWithDataProcessingRestricted
{
  self.settings.stubbedIsDataProcessingRestricted = YES;

  [FBSDKCrashShield analyze:self.coreKitCrashLogs];
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

- (void)testPostingNonCoreKitCrashLogsWithDataProcessingRestricted
{
  self.settings.stubbedIsDataProcessingRestricted = YES;

  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

- (void)testPostingCoreKitCrashLogsWithDataProcessingUnrestricted
{
  // Setup
  self.settings.stubbedIsDataProcessingRestricted = NO;
  self.settings.appID = @"appID";

  // Act
  [FBSDKCrashShield analyze:self.coreKitCrashLogs];

  XCTAssertNotNil([self.graphRequestFactory capturedGraphPath]);
}

- (void)testPostingNonCoreKitCrashLogsWithDataProcessingUnrestricted
{
  self.settings.stubbedIsDataProcessingRestricted = NO;
  self.settings.appID = @"appID";

  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

// MARK: - Helpers

- (NSArray<NSDictionary<NSString *, id> *> *)coreKitCrashLogs
{
  return [FBSDKCrashShieldTests getCrashLogs:YES];
}

- (NSArray<NSDictionary<NSString *, id> *> *)nonCoreKitCrashLogs
{
  return [FBSDKCrashShieldTests getCrashLogs:NO];
}

+ (NSArray<NSDictionary<NSString *, id> *> *)getCrashLogs:(BOOL)isCoreKitFeature
{
  NSArray<NSString *> *callstack = isCoreKitFeature ? @[@"(4 DEV METHODS)",
                                                        @"+[FBSDKCodelessIndexer crash]+84",
                                                        @"(22 DEV METHODS)"] : @[@"(4 DEV METHODS)",
                                                                                 @"+[FBSDKTooltipView crash]+84",
                                                                                 @"(22 DEV METHODS)"];
  NSArray<NSDictionary<NSString *, id> *> *crashLogs = @[@{
                                                           @"callstack" : callstack,
                                                           @"reason" : @"NSInternalInconsistencyException",
                                                           @"fb_sdk_version" : @"5.6.0",
                                                           @"timestamp" : @"1572036095",
                                                           @"app_id" : @"2416630768476176",
                                                           @"device_model" : @"iPad5,3",
                                                           @"device_os" : @"ios",
                                                           @"device_os_version" : @"13.1.3",
  }];
  return crashLogs;
}

@end
