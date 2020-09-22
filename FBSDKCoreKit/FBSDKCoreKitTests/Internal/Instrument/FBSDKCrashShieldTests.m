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

#import "FBSDKCrashShield.h"
#import "FBSDKFeatureManager.h"

@interface FBSDKCrashShield ()

+ (nullable NSString *)getFeature:(NSArray<NSString *> *)callstack;
+ (nullable NSString *)getClassName:(NSString *)entry;

@end

@interface FBSDKCrashShieldTests : XCTestCase
@end

@implementation FBSDKCrashShieldTests

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

- (void)testAnalyzeCrashCausedByCoreKitFeature
{
  NSArray<NSDictionary<NSString *, id> *> *crashLogs = [FBSDKCrashShieldTests getCrashLogs:YES];
  id mockCrashShield = [OCMockObject niceMockForClass:[FBSDKCrashShield class]];
  id mockFeatureManager = [OCMockObject niceMockForClass:[FBSDKFeatureManager class]];

  [[[mockCrashShield expect] andForwardToRealObject] getFeature:crashLogs[0][@"callstack"]];
  [[[mockFeatureManager expect] andForwardToRealObject] disableFeature:@"CodelessEvents"];

  [FBSDKCrashShield analyze:crashLogs];

  [mockFeatureManager verify];
  [mockCrashShield verify];
}

- (void)testAnalyzeCrashCausedByNonCoreKitFeature
{
  NSArray<NSDictionary<NSString *, id> *> *crashLogs = [FBSDKCrashShieldTests getCrashLogs:NO];
  id mockCrashShield = [OCMockObject niceMockForClass:[FBSDKCrashShield class]];
  id mockFeatureManager = [OCMockObject niceMockForClass:[FBSDKFeatureManager class]];

  [[[mockCrashShield expect] andForwardToRealObject] getFeature:crashLogs[0][@"callstack"]];
  [[[mockFeatureManager reject] andForwardToRealObject] disableFeature:[OCMArg any]];

  [FBSDKCrashShield analyze:crashLogs];
  [mockCrashShield verify];
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
