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

#import "FBSDKCrashObserver.h"
#import "FBSDKFeatureManager.h"

@interface FBSDKCrashObserver ()

+ (FBSDKCrashObserver *)sharedInstance;

@end

@interface FBSDKCrashObserverTests : XCTestCase
@end

@implementation FBSDKCrashObserverTests

- (void)testDidReceiveCrashLogs
{
  FBSDKCrashObserver *crashObserver = [FBSDKCrashObserver sharedInstance];

  id crashHandlerMock = [OCMockObject niceMockForClass:[FBSDKCrashHandler class]];

  NSArray<NSDictionary<NSString *, id> *> *processedCrashLogs = [NSMutableArray array];

  // crash log array is empty
  [[crashHandlerMock expect] clearCrashReportFiles];
  [crashObserver didReceiveCrashLogs:processedCrashLogs];
  [crashHandlerMock verify];

  // crash log array is not empty
  processedCrashLogs = [FBSDKCrashObserverTests getCrashLogs];
  id featureManagerMock = [OCMockObject niceMockForClass:[FBSDKFeatureManager class]];

  [[featureManagerMock expect] checkFeature:FBSDKFeatureCrashShield completionBlock:[OCMArg any]];
  [crashObserver didReceiveCrashLogs:processedCrashLogs];
  [featureManagerMock verify];
}

+ (NSArray<NSDictionary<NSString *, id> *> *)getCrashLogs
{
  NSArray<NSString *> *callstack = @[@"(4 DEV METHODS)",
                                     @"+[FBSDKCodelessIndexer crash]+84",
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
