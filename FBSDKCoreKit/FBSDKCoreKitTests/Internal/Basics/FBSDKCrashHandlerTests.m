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

#include <signal.h>

#import "FBSDKCrashObserver.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKSettings.h"

@interface FBSDKCrashHandler ()

+ (void)uninstallExceptionsHandler;
+ (NSArray<NSString *> *)getCrashLogFileNames:(NSArray<NSString *> *)files;
+ (NSString *)getPathToCrashFile:(NSString *)timestamp;
+ (NSString *)getPathToLibDataFile:(NSString *)identifier;
+ (BOOL)callstack:(NSArray<NSString *> *)callstack
   containsPrefix:(NSArray<NSString *> *)prefixList;
+ (NSArray<NSDictionary<NSString *, id> *> *)filterCrashLogs:(NSArray<NSString *> *)prefixList
                                          processedCrashLogs:(NSArray<NSDictionary<NSString *, id> *> *)processedCrashLogs;
+ (void)saveSignal:(int)signal withCallStack:(NSArray<NSString *> *)callStack;
+ (void)saveCrashLog:(NSDictionary<NSString *, id> *)crashLog;

@end

@interface FBSDKCrashHandlerTests : XCTestCase
@end

@implementation FBSDKCrashHandlerTests

- (void)setUp
{
  [FBSDKCrashObserver enable];
}

- (void)testSaveSignal
{
  NSArray<NSString *> *callStack = @[@"(2 DEV METHODS)",
                                     @"-[FBSDKAccessToken getPermissions]+2321432",
                                     @"-[FBSDKAccessToken getPermissions]+2324084",
                                     @"(14 DEV METHODS)", ];
  id handlerMock = [OCMockObject niceMockForClass:[FBSDKCrashHandler class]];
  [[handlerMock expect] saveCrashLog:[OCMArg any]];
  [FBSDKCrashHandler saveSignal:11 withCallStack:callStack]; // SIGSEGV
  [handlerMock verify];
}

- (void)testGetFBSDKVersion
{
  NSString *basicsVersion = [FBSDKCrashHandler getFBSDKVersion];
  NSString *sdkVersion = [FBSDKSettings sdkVersion];
  XCTAssertEqual(basicsVersion, sdkVersion);
}

- (void)testGetCrashLogFileNames
{
  NSArray<NSString *> *files = @[@"crash_log_1576471375.json",
                                 @"crash_lib_data_05DEDC8AFC724E09A5E68190C492B92B.json",
                                 @"DATA_DETECTION_ADDRESS_1.weights",
                                 @"SUGGEST_EVENT_3.weights",
                                 @"SUGGEST_EVENT_3.rules",
                                 @"crash.text",
  ];
  NSArray<NSString *> *result1 = [FBSDKCrashHandler getCrashLogFileNames:files];
  XCTAssertTrue([result1 containsObject:@"crash_log_1576471375.json"]);

  XCTAssertFalse([result1 containsObject:@"crash_lib_data_05DEDC8AFC724E09A5E68190C492B92B.json"]);
  XCTAssertFalse([result1 containsObject:@"DATA_DETECTION_ADDRESS_1.weights"]);
  XCTAssertFalse([result1 containsObject:@"SUGGEST_EVENT_3.weights"]);
  XCTAssertFalse([result1 containsObject:@"SUGGEST_EVENT_3.rules"]);
  XCTAssertFalse([result1 containsObject:@"crash.text"]);

  files = [NSArray array];
  NSArray<NSString *> *result2 = [FBSDKCrashHandler getCrashLogFileNames:files];
  XCTAssertTrue(result2.count == 0);
}

- (void)testGetPathToCrashFile
{
  NSString *timestampMock = @"test_timestamp";
  NSString *crashLogFileName = [NSString stringWithFormat:@"crash_log_%@.json", timestampMock];
  NSString *pathToCrashFile = [FBSDKCrashHandler getPathToCrashFile:timestampMock];

  XCTAssertTrue([pathToCrashFile hasSuffix:crashLogFileName]);
}

- (void)testGetPathToLibDataFile
{
  NSString *identifierMock = @"test_identifier";
  NSString *libDataFileName = [NSString stringWithFormat:@"crash_lib_data_%@.json", identifierMock];
  NSString *pathToLibDataFile = [FBSDKCrashHandler getPathToLibDataFile:identifierMock];

  XCTAssertTrue([pathToLibDataFile hasSuffix:libDataFileName]);
}

- (void)testCallStackContainsPrefix
{
  NSArray<NSString *> *prefixList = @[@"FBSDK", @"_FBSDK"];
  NSArray<NSString *> *callStack1 = @[
    @"(2 DEV METHODS)",
    @"-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+2110632",
    @"-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+10540",
    @"(14 DEV METHODS)",
  ];
  XCTAssertTrue([FBSDKCrashHandler callstack:callStack1 containsPrefix:prefixList]);

  NSArray<NSString *> *callStack2 = @[
    @"(2 DEV METHODS)",
    @"-[FBAdPersistentCacheImpl storeAssetInMemory:forKey:expiration:]+14455428",
    @"(12 DEV METHODS)",
  ];
  XCTAssertFalse([FBSDKCrashHandler callstack:callStack2 containsPrefix:prefixList]);
}

- (void)testFilterCrashLogs
{
  NSArray *filteredCrashLogs = [FBSDKCrashHandler filterCrashLogs:@[@"FBSDK", @"_FBSDK"] processedCrashLogs:[self mockProcessedCrashLogs]];

  XCTAssertEqual(1, filteredCrashLogs.count);

  NSDictionary<NSString *, id> *crashLog = filteredCrashLogs[0];

  XCTAssertEqual(crashLog[@"app_version"], @"4.16(4)");
  XCTAssertEqual(crashLog[@"callstack"][0], @"(2 DEV METHODS)");
  XCTAssertEqual(crashLog[@"callstack"][1], @"-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+2110632");
  XCTAssertEqual(crashLog[@"callstack"][2], @"-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+10540");
  XCTAssertEqual(crashLog[@"callstack"][3], @"(14 DEV METHODS)");
  XCTAssertEqual(crashLog[@"reason"], @"InvalidOperationException");
  XCTAssertEqual(crashLog[@"timestamp"], @"1585764970");
  XCTAssertEqual(crashLog[@"device_model"], @"iPhone7,2");
  XCTAssertEqual(crashLog[@"device_os_version"], @"12.4.1");
}

- (NSArray<NSDictionary<NSString *, id> *> *)mockProcessedCrashLogs
{
  NSDictionary<NSString *, id> *crashLog1 = @{
    @"app_version" : @"4.16(4)",
    @"callstack" : @[
      @"(2 DEV METHODS)",
      @"-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+2110632",
      @"-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+10540",
      @"(14 DEV METHODS)",
    ],
    @"reason" : @"InvalidOperationException",
    @"timestamp" : @"1585764970",
    @"device_model" : @"iPhone7,2",
    @"device_os_version" : @"12.4.1",
  };

  NSDictionary<NSString *, id> *crashLog2 = @{
    @"app_version" : @"1.173.0(2)",
    @"callstack" : @[
      @"(3 DEV METHODS)",
      @"-[SettingsItemViewController imageWithImage:destination:]+2110632",
      @"(6 DEV METHODS)",
    ],
    @"reason" : @"NSInvalidArgumentException",
    @"timestamp" : @"1585764970",
    @"device_model" : @"iPad4,1",
    @"device_os_version" : @"12.4.5",
  };
  return @[crashLog1, crashLog2];
}

@end
