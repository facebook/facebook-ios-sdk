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

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKCrashShield.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKTestCase.h"

@interface FBSDKCrashShield (Testing)

+ (nullable NSString *)getFeature:(NSArray<NSString *> *)callstack;
+ (nullable NSString *)getClassName:(NSString *)entry;

@end

@interface FBSDKCrashShieldTests : FBSDKTestCase
@end

@implementation FBSDKCrashShieldTests

// MARK: - Get Feature

- (void)testGetFeature
{
  // gated feature in corekit
  NSArray<NSString *> *callstack1 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKMetadataIndexer crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName1 = [FBSDKCrashShield getFeature:callstack1];
  XCTAssertTrue([featureName1 isEqualToString:@"AAM"]);

  NSArray<NSString *> *callstack2 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKCodelessIndexer crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName2 = [FBSDKCrashShield getFeature:callstack2];
  XCTAssertTrue([featureName2 isEqualToString:@"CodelessEvents"]);

  NSArray<NSString *> *callstack3 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKRestrictiveDataFilterManager crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName3 = [FBSDKCrashShield getFeature:callstack3];
  XCTAssertTrue([featureName3 isEqualToString:@"RestrictiveDataFiltering"]);

  NSArray<NSString *> *callstack4 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKErrorReport crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName4 = [FBSDKCrashShield getFeature:callstack4];
  XCTAssertTrue([featureName4 isEqualToString:@"ErrorReport"]);

  // feature in other kit
  NSArray<NSString *> *callstack5 = @[@"(4 DEV METHODS)",
                                      @"+[FBSDKVideoUploader crash]+84",
                                      @"(22 DEV METHODS)"];

  NSString *featureName5 = [FBSDKCrashShield getFeature:callstack5];
  XCTAssertNil(featureName5);
}

- (void)testParsingFeatureFromValidCallstack
{
  NSArray<NSString *> *callstack = @[@"(4 DEV METHODS)",
                                     @"+[FBSDKVideoUploader crash]+84",
                                     @"(22 DEV METHODS)"];
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield getFeature:[Fuzzer randomizeWithJson:callstack]];
  }
}

- (void)testParsingFeatureFromGarbage
{
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield getFeature:Fuzzer.random];
  }
}

// MARK: - Get Class Name

- (void)testGetClassName
{
  // class method
  NSString *entry1 = @"+[FBSDKRestrictiveDataFilterManager crash]+84";
  NSString *className1 = [FBSDKCrashShield getClassName:entry1];
  XCTAssertTrue([className1 isEqualToString:@"FBSDKRestrictiveDataFilterManager"]);

  // instance method
  NSString *entry2 = @"-[FBSDKRestrictiveDataFilterManager crash]+84";
  NSString *className2 = [FBSDKCrashShield getClassName:entry2];
  XCTAssertTrue([className2 isEqualToString:@"FBSDKRestrictiveDataFilterManager"]);

  // ineligible format
  NSString *entry3 = @"(6 DEV METHODS)";
  NSString *className3 = [FBSDKCrashShield getClassName:entry3];
  XCTAssertNil(className3);
}

- (void)testParsingClassName
{
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield getClassName:Fuzzer.random];
  }
}

- (void)testAnalyzingEmptyCrashLogs
{
  // Should not create a graph request for posting a non-existent crash
  OCMReject(ClassMethod([self.graphRequestMock alloc]));

  [FBSDKCrashShield analyze:@[]];
}

- (void)testAnalyzingInvalidCrashLogs
{
  for (int i = 0; i < 100; i++) {
    [FBSDKCrashShield getClassName:[Fuzzer randomizeWithJson:self.coreKitCrashLogs]];
  }
}

// MARK: - Analyze: Disabling Features

- (void)testDisablingCoreKitFeatureWithDataProcessingRestricted
{
  [self stubIsDataProcessingRestricted:YES];
  [self preventGraphRequest];

  [FBSDKCrashShield analyze:self.coreKitCrashLogs];

  // Should disable a core feature found in a crashlog regardless of data processing permissions
  OCMVerify(ClassMethod([self.featureManagerClassMock disableFeature:@"CodelessEvents"]));
}

- (void)testDisablingNonCoreKitFeatureWithDataProcessingRestricted
{
  [self stubIsDataProcessingRestricted:YES];
  [self preventGraphRequest];

  // Should not disable a non core feature found in a crashlog regardless of data processing permissions
  OCMReject(ClassMethod([self.featureManagerClassMock disableFeature:OCMArg.any]));

  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];
}

- (void)testDisablingCoreKitFeatureWithDataProcessingUnrestricted
{
  [self stubIsDataProcessingRestricted:NO];
  [self preventGraphRequest];

  [FBSDKCrashShield analyze:self.coreKitCrashLogs];

  // Should disable a core feature found in a crashlog regardless of data processing permissions
  OCMVerify(ClassMethod([self.featureManagerClassMock disableFeature:@"CodelessEvents"]));
}

- (void)testDisablingNonCoreKitFeatureWithDataProcessingUnrestricted
{
  [self stubIsDataProcessingRestricted:NO];
  [self preventGraphRequest];

  // Should not disable a non core feature found in a crashlog regardless of data processing permissions
  OCMReject(ClassMethod([self.featureManagerClassMock disableFeature:OCMArg.any]));

  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];
}

// MARK: - Analyze: Posting Crash Logs

- (void)testPostingCoreKitCrashLogsWithDataProcessingRestricted
{
  [self stubIsDataProcessingRestricted:YES];

  OCMReject([self.graphRequestMock alloc]);

  [FBSDKCrashShield analyze:self.coreKitCrashLogs];
}

- (void)testPostingNonCoreKitCrashLogsWithDataProcessingRestricted
{
  [self stubIsDataProcessingRestricted:YES];

  OCMReject([self.graphRequestMock alloc]);

  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];
}

- (void)testPostingCoreKitCrashLogsWithDataProcessingUnrestricted
{
  // Setup
  [self stubIsDataProcessingRestricted:NO];
  [self stubAppID:self.appID];
  [self stubDate];
  [self stubTimeIntervalSince1970WithTimeInterval:10];

  [self addInitializerStubsToGraphRequestMock];
  OCMExpect([self.graphRequestMock startWithCompletionHandler:nil]);

  // Act
  [FBSDKCrashShield analyze:self.coreKitCrashLogs];

  // Assert
  NSString *expectedPath = [NSString stringWithFormat:@"%@/instruments", self.appID];
  NSDictionary *expectedParameters = @{
    @"crash_shield" : [self encodedCoreKitFeatureDataWithTimestamp:@"10"]
  };
  OCMVerify(
    [self.graphRequestMock initWithGraphPath:expectedPath
                                  parameters:expectedParameters
                                  HTTPMethod:FBSDKHTTPMethodPOST]
  );
  OCMVerify([self.graphRequestMock startWithCompletionHandler:nil]);
}

- (void)testPostingNonCoreKitCrashLogsWithDataProcessingUnrestricted
{
  [self stubIsDataProcessingRestricted:NO];
  [self stubAppID:self.appID];
  [self stubDate];
  [self stubTimeIntervalSince1970WithTimeInterval:10];

  [self addInitializerStubsToGraphRequestMock];

  OCMReject(
    [self.graphRequestMock initWithGraphPath:OCMArg.any
                                  parameters:OCMArg.any
                                  HTTPMethod:FBSDKHTTPMethodPOST]
  );
  OCMReject([self.graphRequestMock startWithCompletionHandler:nil]);

  [FBSDKCrashShield analyze:self.nonCoreKitCrashLogs];
}

// MARK: - Helpers

- (void)addInitializerStubsToGraphRequestMock
{
  OCMStub(ClassMethod([self.graphRequestMock alloc])).andReturn(self.graphRequestMock);
  OCMStub(
    [self.graphRequestMock initWithGraphPath:OCMArg.any
                                  parameters:OCMArg.any
                                  HTTPMethod:FBSDKHTTPMethodPOST]
  ).andReturn(self.graphRequestMock);
}

- (NSString *)encodedCoreKitFeatureDataWithTimestamp:(NSString *)timestamp
{
  NSData *featureData = [FBSDKTypeUtility dataWithJSONObject:@{
                           @"feature_names" : @[@"CodelessEvents"],
                           @"timestamp" : timestamp
                         } options:0 error:nil];
  return [[NSString alloc] initWithData:featureData encoding:NSUTF8StringEncoding];
}

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

- (void)preventGraphRequest
{
  OCMStub(ClassMethod([self.graphRequestMock alloc])).andReturn(self.graphRequestMock);
  OCMStub(
    [self.graphRequestMock initWithGraphPath:OCMArg.any
                                  parameters:OCMArg.any
                                  HTTPMethod:FBSDKHTTPMethodPOST]
  ).andReturn(self.graphRequestMock);
  OCMStub([self.graphRequestMock startWithCompletionHandler:nil]);
}

@end
