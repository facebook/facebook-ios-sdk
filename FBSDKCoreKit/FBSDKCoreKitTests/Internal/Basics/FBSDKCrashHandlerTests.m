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

#import <OCMock/OCMock.h>

#import "FBSDKCrashHandler.h"
#import "FBSDKSettings.h"

@interface FBSDKCrashHandler ()

+ (void)uninstallExceptionsHandler;
+ (NSArray<NSString *> *)getCrashLogFileNames:(NSArray<NSString *> *)files;
+ (NSString *)getPathToCrashFile:(NSString *)timestamp;
+ (NSString *)getPathToLibDataFile:(NSString *)identifier;
+ (BOOL)callstack:(NSArray<NSString *> *)callstack
   containsPrefix:(NSArray<NSString *> *)prefixList;

@end

@interface FBSDKCrashHandlerTests : XCTestCase
@end

@implementation FBSDKCrashHandlerTests

- (void)setUp
{
  [FBSDKCrashHandler initialize];
}

- (void)testDisable
{
  id hanlderMock = [OCMockObject niceMockForClass:[FBSDKCrashHandler class]];
  [[hanlderMock expect] uninstallExceptionsHandler];
  [FBSDKCrashHandler disable];
  [hanlderMock verify];
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
  NSString *crashLogFileName =  [NSString stringWithFormat:@"crash_log_%@.json", timestampMock];
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

@end
