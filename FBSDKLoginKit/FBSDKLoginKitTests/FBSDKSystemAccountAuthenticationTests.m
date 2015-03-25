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

#import <Accounts/Accounts.h>

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKLoginCompletion+Internal.h"
#import "FBSDKLoginManager+Internal.h"
#import "FBSDKLoginManagerLoginResult.h"
#import "FBSDKLoginUtilityTests.h"

@interface FBSDKSystemAccountAuthenticationTests : XCTestCase
@end

@implementation FBSDKSystemAccountAuthenticationTests
{
  id _mockNSBundle;
}

- (void)setUp
{
  _mockNSBundle = [FBSDKLoginUtilityTests mainBundleMock];

  [FBSDKAccessToken setCurrentAccessToken:nil];

  // Some tests may require an App ID to set in the loginParams dictionary if a fallback
  // method is employed. For our purposes it doesn't matter what it is.
  [FBSDKSettings setAppID:@"12345678"];
}

- (void)testOpenDoesNotTrySystemAccountAuthWithNativeBehavior
{
  [self testImplOpenDoesNotTrySystemAccountAuthWithBehavior:FBSDKLoginBehaviorNative];
}

- (void)testOpenDoesNotTrySystemAccountAuthWithBrowserBehavior
{
  [self testImplOpenDoesNotTrySystemAccountAuthWithBehavior:FBSDKLoginBehaviorBrowser];
}

- (void)testOpenDoesNotTrySystemAccountAuthWithWebBehavior
{
  [self testImplOpenDoesNotTrySystemAccountAuthWithBehavior:FBSDKLoginBehaviorWeb];
}

- (void)testImplOpenDoesNotTrySystemAccountAuthWithBehavior:(FBSDKLoginBehavior)behavior
{
  id target = [OCMockObject partialMockForObject:[[FBSDKLoginManager alloc] init]];

  id shortCircuitAuthBlock = ^ (NSInvocation *invocation) {
    BOOL returnValue = YES;
    [invocation setReturnValue:&returnValue];
  };

  [[[target stub] andDo:shortCircuitAuthBlock] performNativeLogInWithParameters:[OCMArg any] error:[OCMArg anyObjectRef]];
  [[[target stub] andDo:shortCircuitAuthBlock] performBrowserLogInWithParameters:[OCMArg any] error:[OCMArg anyObjectRef]];
  [[[target stub] andDo:shortCircuitAuthBlock] performWebLogInWithParameters:[OCMArg any]];

  // the test fails if system auth is performed
  [[[target stub] andDo:^(NSInvocation *invocation) {
    XCTFail();

    BOOL returnValue = YES;
    [invocation setReturnValue:&returnValue];
  }] performSystemLogIn];

  [target setLoginBehavior:behavior];
  [target logInWithReadPermissions:@[@"public_profile"] handler:nil];
}

- (void)testSystemAccountSuccess
{
  id target = [OCMockObject partialMockForObject:[[FBSDKLoginManager alloc] init]];

  NSString *accessToken = @"CAA1234";
  NSSet *permissions = [NSSet setWithObject:@"public_profile"];

  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertEqualObjects(result.token.permissions, permissions);
    XCTAssertEqualObjects(result.token.declinedPermissions, [NSSet set]);
    XCTAssertEqualObjects(result.token.tokenString, accessToken);
    XCTAssertFalse(result.isCancelled);
    XCTAssertEqualObjects(result.grantedPermissions, permissions);
    XCTAssertNil(result.declinedPermissions);
    XCTAssertNil(error);
  }];

  FBSDKLoginCompletionParameters *parameters = [[FBSDKLoginCompletionParameters alloc] init];
  parameters.accessTokenString = accessToken;
  parameters.permissions = permissions;
  parameters.declinedPermissions = [NSSet set];
  parameters.appID = [FBSDKSettings appID];
  parameters.userID = @"37175274";

  [target completeAuthentication:parameters];
}

- (void)testSystemAccountCancellationGeneratesError
{
  id target = [[FBSDKLoginManager alloc] init];
  NSError *error = [NSError errorWithDomain:ACErrorDomain code:ACErrorPermissionDenied userInfo:nil];

  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *authError) {
    XCTAssertNil(result.token);
    XCTAssertTrue(result.isCancelled);
    XCTAssertNil(result.grantedPermissions);
    XCTAssertNil(result.declinedPermissions);
    XCTAssertNil(authError);
  }];

  [target continueSystemLogInWithTokenString:nil error:error state:nil];
}

- (void)testSystemAccountNotAvailableOnServerTriesNextAuthMethod
{
  [self testSystemAccountNotAvailableTriesNextAuthMethodServer:NO device:YES];
}

- (void)testSystemAccountNotAvailableOnDeviceTriesNextAuthMethod
{
  [self testSystemAccountNotAvailableTriesNextAuthMethodServer:YES device:NO];
}

- (void)testSystemAccountNotAvailableAnywhereTriesNextAuthMethod
{
  [self testSystemAccountNotAvailableTriesNextAuthMethodServer:NO device:NO];
}

- (void)testSystemAccountNotAvailableTriesNextAuthMethodServer:(BOOL)serverSupports
                                                        device:(BOOL)deviceSupports
{
  id target = [OCMockObject partialMockForObject:[[FBSDKLoginManager alloc] init]];
  [target setLoginBehavior:FBSDKLoginBehaviorSystemAccount];

  NSSet *permissions = [NSSet setWithObject:@"public_profile"];
  NSError *error = [NSError errorWithDomain:ACErrorDomain code:ACErrorAccountNotFound userInfo:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"fallback callback"];
  __block unsigned invocationCount = 0;

  id attemptedAuthBlock = ^ (NSInvocation *invocation) {
    invocationCount++;

    BOOL returnValue = YES;
    [invocation setReturnValue:&returnValue];
    [expectation fulfill];
  };

  [[[target stub] andDo:attemptedAuthBlock] performNativeLogInWithParameters:[OCMArg any] error:[OCMArg anyObjectRef]];
  [[[target stub] andDo:attemptedAuthBlock] performBrowserLogInWithParameters:[OCMArg any] error:[OCMArg anyObjectRef]];

  [[[target stub] andDo:^ (NSInvocation *invocation) {
    invocationCount++;

    if (!deviceSupports) {
      [target fallbackToNativeBehavior];
    }
  }] beginSystemLogIn];

  // this shouldn't actually be invoked
  [[[target stub] andDo:^(NSInvocation *invocation) {
    invocationCount++;

    BOOL returnValue = YES;
    [invocation setReturnValue:&returnValue];
  }] performWebLogInWithParameters:[OCMArg any]];

  FBSDKServerConfiguration *configuration =
    [[FBSDKServerConfiguration alloc] initWithAppID:[FBSDKSettings appID]
                                            appName:@"Unit Tests"
                                loginTooltipEnabled:NO
                                   loginTooltipText:nil
                               advertisingIDEnabled:NO
                             implicitLoggingEnabled:NO
                     implicitPurchaseLoggingEnabled:NO
                        systemAuthenticationEnabled:serverSupports
                               dialogConfigurations:nil
                                          timestamp:[NSDate date]
                                 errorConfiguration:nil];
  [FBSDKServerConfigurationManager _didLoadServerConfiguration:configuration appID:[FBSDKSettings appID] error:nil didLoadFromUserDefaults:YES];

  [target setRequestedPermissions:permissions];
  if (deviceSupports) {
    XCTAssertTrue(!serverSupports, @"Invalid Test Settings");
    [target continueSystemLogInWithTokenString:nil error:error state:nil];
  } else {
    [target logInWithBehavior:FBSDKLoginBehaviorSystemAccount];
  }

  // if the device supports system auth and the app configuration doesn't then we expect only native to be invoked
  // if the device doesn't support system auth and the app configuration does then we expect system auth and native to be invoked
  [self waitForExpectationsWithTimeout:0.1 handler:^(NSError *timeoutError) {
    XCTAssertNil(timeoutError);
  }];
  XCTAssertEqual(invocationCount, (!serverSupports ? 1 : 2));
}

@end
