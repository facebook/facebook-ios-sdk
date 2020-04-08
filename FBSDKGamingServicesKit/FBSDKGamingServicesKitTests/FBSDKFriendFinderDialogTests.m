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

#import <FBSDKGamingServicesKit/FBSDKGamingServicesKit.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKGamingServicesKitTestUtility.h"

@interface FBSDKFriendFinderDialogTests : XCTestCase
@end

@implementation FBSDKFriendFinderDialogTests
{
  id _mockToken;
  id _mockApp;
}

- (void)setUp
{
  [super setUp];

  _mockToken = OCMClassMock([FBSDKAccessToken class]);
  [FBSDKAccessToken setCurrentAccessToken:_mockToken];

  _mockApp = OCMClassMock([UIApplication class]);
  OCMStub([_mockApp sharedApplication]).andReturn(_mockApp);
}

- (void)testFailureWhenNoValidAccessTokenPresent
{
  [FBSDKAccessToken setCurrentAccessToken:nil];

  __block BOOL actioned = false;
  [FBSDKFriendFinderDialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
    XCTAssert(error.code == FBSDKErrorAccessTokenRequired, "Expected error requiring a valid access token");
    actioned = true;
  }];

  XCTAssertTrue(actioned);
}

- (void)testServiceIsCalledCorrectly
{
  OCMStub([_mockToken appID]).andReturn(@"123");
  OCMStub([_mockApp
           openURL:[OCMArg any]
           options:[OCMArg any]
           completionHandler:([OCMArg invokeBlockWithArgs:@(false), nil])]);

  id expectation = [self expectationWithDescription:@"callback"];

  [FBSDKFriendFinderDialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];

  id urlCheck = [OCMArg checkWithBlock:^BOOL(id obj) {
    return [[(NSURL *)obj absoluteString] isEqualToString:@"https://fb.gg/me/friendfinder/123"];
  }];
  OCMVerify([_mockApp openURL:urlCheck options:[OCMArg any] completionHandler:[OCMArg any]]);
}

- (void)testFailuresReturnAnError
{
  OCMStub([_mockApp
           openURL:[OCMArg any]
           options:[OCMArg any]
           completionHandler:([OCMArg invokeBlockWithArgs:@(false), nil])]);

  id expectation = [self expectationWithDescription:@"callback"];
  [FBSDKFriendFinderDialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
    XCTAssertFalse(success);
    XCTAssert(error.code == FBSDKErrorBridgeAPIInterruption);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testHandlingOfCallbackURL
{
  id settings = OCMClassMock([FBSDKSettings class]);
  OCMStub([settings appID]).andReturn(@"123");

  __block id<FBSDKURLOpening> delegate;
  [FBSDKGamingServicesKitTestUtility captureURLDelegateFromBridgeAPI:^(id<FBSDKURLOpening> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [FBSDKFriendFinderDialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
    XCTAssertTrue(success);
    actioned = true;
  }];

  [delegate application:_mockApp openURL:[NSURL URLWithString:@"fb123://friendfinder"] sourceApplication:@"foo" annotation:nil];

  XCTAssertTrue(actioned);
}

- (void)testHandlingOfUserManuallyReturningToOriginalApp
{
  __block id<FBSDKURLOpening> delegate;
  [FBSDKGamingServicesKitTestUtility captureURLDelegateFromBridgeAPI:^(id<FBSDKURLOpening> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [FBSDKFriendFinderDialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
    XCTAssertTrue(success);
    actioned = true;
  }];

  [delegate applicationDidBecomeActive:_mockApp];

  XCTAssertTrue(actioned);
}

@end
