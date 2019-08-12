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

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTestUtility.h"

// An extension that redeclares a private method so that it can be mocked
@interface FBSDKApplicationDelegate ()
- (BOOL)isAppLaunched;
@end

@interface FBSDKApplicationDelegateTests : XCTestCase {
  id _settingsMock;
}

@end

static id g_mockNSBundle;

@interface FBSDKApplicationDelegate(Test)

- (void)_logSDKInitialize;

@end

@implementation FBSDKApplicationDelegateTests

- (void)setUp {
  [super setUp];
  g_mockNSBundle = [FBSDKCoreKitTestUtility mainBundleMock];
  _settingsMock = OCMStrictClassMock([FBSDKSettings class]);
}

- (void)tearDown {
  [g_mockNSBundle stopMocking];
  g_mockNSBundle = nil;
  [_settingsMock stopMocking];
  _settingsMock = nil;
}

- (void)testAutoLogAppEventsEnabled {
  [OCMStub(ClassMethod([_settingsMock autoLogAppEventsEnabled])) andReturnValue: OCMOCK_VALUE(YES)];


  FBSDKApplicationDelegate *delegate = [FBSDKApplicationDelegate sharedInstance];
  id delegateMock = OCMPartialMock(delegate);
  [OCMStub([delegateMock isAppLaunched]) andReturnValue: OCMOCK_VALUE(NO)];

  [delegate application:nil didFinishLaunchingWithOptions:nil];

  OCMVerify([delegateMock _logSDKInitialize]);
}

- (void)testAutoLogAppEventsDisabled {
  [OCMStub(ClassMethod([_settingsMock autoLogAppEventsEnabled])) andReturnValue: OCMOCK_VALUE(NO)];

  FBSDKApplicationDelegate *delegate = [FBSDKApplicationDelegate sharedInstance];
  id delegateMock = OCMPartialMock(delegate);
  [OCMStub([delegateMock isAppLaunched]) andReturnValue: OCMOCK_VALUE(NO)];

  [[delegateMock reject] _logSDKInitialize];

  id app = OCMClassMock([UIApplication class]);
  [delegate application:app didFinishLaunchingWithOptions:nil];
}

@end
