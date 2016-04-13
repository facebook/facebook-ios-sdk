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

#import <objc/runtime.h>

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
  Method _originalIsRegisteredCheck;
  Method _swizzledIsRegisteredCheck;
}

+ (id)internalUtilityMock
{
  // swizzle out mainBundle - XCTest returns the XCTest program bundle instead of the target,
  // and our keychain code is coded against mainBundle.
  id mockUtility = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [[[mockUtility stub] andReturnValue:OCMOCK_VALUE(YES)] isRegisteredURLScheme:[OCMArg any]];
  [[mockUtility stub] checkRegisteredCanOpenURLScheme:[OCMArg any]];
  return mockUtility;
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
  id mockUtility = [FBSDKSystemAccountAuthenticationTests internalUtilityMock];

  id target = [OCMockObject partialMockForObject:[[FBSDKLoginManager alloc] init]];

  id shortCircuitAuthBlock = ^ (NSInvocation *invocation) {
    void(^handler)(BOOL, NSError*);
    [invocation getArgument:&handler atIndex:3];
    handler(YES, nil);
  };

  id shortCircuitBrowserAuthBlock = ^ (NSInvocation *invocation) {
    void(^handler)(BOOL, NSString *,NSError*);
    [invocation getArgument:&handler atIndex:3];
    handler(YES, @"", nil);
  };

  [[[target stub] andDo:shortCircuitAuthBlock] performNativeLogInWithParameters:[OCMArg any] handler:[OCMArg any]];
  [[[target stub] andDo:shortCircuitBrowserAuthBlock] performBrowserLogInWithParameters:[OCMArg any] handler:[OCMArg any]];
  [[[target stub] andDo:shortCircuitAuthBlock] performWebLogInWithParameters:[OCMArg any] handler:[OCMArg any]];

  // the test fails if system auth is performed
  [[[target stub] andDo:^(NSInvocation *invocation) {
    XCTFail();

    BOOL returnValue = YES;
    [invocation setReturnValue:&returnValue];
  }] performSystemLogIn];

  [target setLoginBehavior:behavior];
  [target logInWithReadPermissions:@[@"public_profile"] fromViewController:nil handler:nil];
  [mockUtility stopMocking];
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

  [target completeAuthentication:parameters expectChallenge:NO];
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
  id mockUtility = [FBSDKSystemAccountAuthenticationTests internalUtilityMock];

  id target = [OCMockObject partialMockForObject:[[FBSDKLoginManager alloc] init]];
  [target setLoginBehavior:FBSDKLoginBehaviorSystemAccount];

  NSSet *permissions = [NSSet setWithObject:@"public_profile"];
  NSError *error = [NSError errorWithDomain:ACErrorDomain code:ACErrorAccountNotFound userInfo:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"fallback callback"];
  __block unsigned invocationCount = 0;

  id attemptedAuthBlock = ^ (NSInvocation *invocation) {
    invocationCount++;

    void(^handler)(BOOL, NSError*);
    [invocation getArgument:&handler atIndex:3];
    handler(YES, nil);
    [expectation fulfill];
  };
  id attemptBrowserAuthBlock = ^ (NSInvocation *invocation) {
    invocationCount++;
    void(^handler)(BOOL, NSString *,NSError*);
    [invocation getArgument:&handler atIndex:3];
    handler(YES, @"", nil);
    [expectation fulfill];
  };

  [[[target stub] andDo:attemptedAuthBlock] performNativeLogInWithParameters:[OCMArg any] handler:[OCMArg any]];
  [[[target stub] andDo:attemptBrowserAuthBlock] performBrowserLogInWithParameters:[OCMArg any] handler:[OCMArg any]];

  [[[target stub] andDo:^ (NSInvocation *invocation) {
    invocationCount++;

    if (!deviceSupports) {
      [target fallbackToNativeBehavior];
    }
  }] beginSystemLogIn];

  FBSDKServerConfiguration *serverConfiguration =
  [[FBSDKServerConfiguration alloc] initWithAppID:[FBSDKSettings appID]
                                          appName:@"Unit Tests"
                              loginTooltipEnabled:NO
                                 loginTooltipText:nil
                                 defaultShareMode:nil
                             advertisingIDEnabled:NO
                           implicitLoggingEnabled:NO
                   implicitPurchaseLoggingEnabled:NO
                      systemAuthenticationEnabled:serverSupports
                            nativeAuthFlowEnabled:serverSupports
                             dialogConfigurations:nil
                                      dialogFlows:nil
                                        timestamp:[NSDate date]
                               errorConfiguration:nil
                           sessionTimeoutInterval:60.0
                                         defaults:NO];
  id serverConfigurationManager = [OCMockObject mockForClass:[FBSDKServerConfigurationManager class]];
  [[[serverConfigurationManager stub] andReturn:serverConfiguration] cachedServerConfiguration];
  [[[serverConfigurationManager stub] andDo:^(NSInvocation *invocation) {
    FBSDKServerConfigurationManagerLoadBlock block;
    [invocation getArgument:&block atIndex:2];
    block(serverConfiguration, nil);
  }] loadServerConfigurationWithCompletionBlock:[OCMArg any]];

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

  [mockUtility stopMocking];
  [serverConfigurationManager stopMocking];
}

@end
