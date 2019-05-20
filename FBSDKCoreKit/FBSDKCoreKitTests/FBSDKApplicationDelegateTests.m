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
  FBSDKApplicationDelegate *_delegate;
  id _delegateMock;
  id _settingsMock;
}

@end

static id g_mockNSBundle;

@interface FBSDKApplicationDelegate(Test)

- (void)_logSDKInitialize;
- (void)applicationDidBecomeActive:(NSNotification *)notification;

@end

@implementation FBSDKApplicationDelegateTests

- (void)setUp {
  [super setUp];
  g_mockNSBundle = [FBSDKCoreKitTestUtility mainBundleMock];
  _settingsMock = OCMStrictClassMock([FBSDKSettings class]);

  _delegate = [FBSDKApplicationDelegate sharedInstance];
  _delegateMock = OCMPartialMock(_delegate);
  [OCMStub([_delegateMock isAppLaunched]) andReturnValue: OCMOCK_VALUE(NO)];
}

- (void)tearDown {
  [g_mockNSBundle stopMocking];
  g_mockNSBundle = nil;
  [_settingsMock stopMocking];
  _settingsMock = nil;
  [_delegateMock stopMocking];
  _delegateMock = nil;
}

- (void)testAutoLogAppEventsEnabled {

  [OCMStub(ClassMethod([_settingsMock isAutoLogAppEventsEnabled])) andReturnValue: OCMOCK_VALUE(YES)];

  id app = OCMClassMock([UIApplication class]);

  [_delegate application:app didFinishLaunchingWithOptions:nil];

  OCMVerify([_delegateMock _logSDKInitialize]);
}

- (void)testAutoLogAppEventsDisabled {
  [OCMStub(ClassMethod([_settingsMock isAutoLogAppEventsEnabled])) andReturnValue: OCMOCK_VALUE(NO)];

  OCMReject([_delegateMock _logSDKInitialize]);

  id app = OCMClassMock([UIApplication class]);
  [_delegate application:app didFinishLaunchingWithOptions:nil];
}

- (void)testAppEventsEnabled {

  [OCMStub(ClassMethod([_settingsMock isAutoLogAppEventsEnabled])) andReturnValue: OCMOCK_VALUE(YES)];

  id appEvents = OCMClassMock([FBSDKAppEvents class]);

  id notification = OCMClassMock([NSNotification class]);
  [_delegate applicationDidBecomeActive:notification];

  OCMVerify([appEvents activateApp]);
}

-(void)testAppEventsDisabled {

  [OCMStub(ClassMethod([_settingsMock isAutoLogAppEventsEnabled])) andReturnValue: OCMOCK_VALUE(NO)];

  id appEvents = OCMStrictClassMock([FBSDKAppEvents class]);
  OCMReject([appEvents activateApp]);

  id notification = OCMClassMock([NSNotification class]);
  [_delegate applicationDidBecomeActive:notification];
}
@end
