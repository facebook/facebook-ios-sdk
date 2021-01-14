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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginUtility.h>
 #import <FBSDKLoginKit+Internal/FBSDKReferralManager+Internal.h>
 #import <FBSDKLoginKit/FBSDKReferralManagerResult.h>
#else
 #import "FBSDKLoginUtility.h"
 #import "FBSDKReferralManager+Internal.h"
 #import "FBSDKReferralManagerResult.h"
#endif

static NSString *const _mockAppID = @"mockAppID";
static NSString *const _mockChallenge = @"mockChallenge";

@interface FBSDKReferralManager (Testing)

- (NSURL *)referralURL;

- (void)handleOpenURLComplete:(BOOL)didOpen error:(NSError *)error;

- (BOOL)validateChallenge:(NSString *)challenge;

@end

@interface FBSDKReferralManagerTests : XCTestCase
{
  FBSDKReferralManager *_manager;
}

@end

@implementation FBSDKReferralManagerTests

- (void)setUp
{
  [super setUp];
  _manager = OCMPartialMock([FBSDKReferralManager new]);
  [FBSDKSettings setAppID:_mockAppID];
}

- (void)mockURLScheme
{
  id FBSDKInternalUtilityMock = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  OCMStub(ClassMethod([FBSDKInternalUtilityMock validateURLSchemes])).andDo(^(NSInvocation *invocation) {
    // Nothing
  });
}

- (void)mockBridgeAPI
{
  id partialBridgeAPIMock = OCMPartialMock([FBSDKBridgeAPI sharedInstance]);
  OCMStub([partialBridgeAPIMock openURLWithSafariViewController:OCMArg.any sender:OCMArg.any fromViewController:OCMArg.any handler:OCMArg.any]).andDo(^(NSInvocation *invocation) {
    // Nothing
  });
}

- (void)testReferralURL
{
  NSURL *url = [_manager referralURL];

  XCTAssertTrue([url.path hasSuffix:@"dialog/share_referral"]);

  NSDictionary *params = [FBSDKInternalUtility parametersFromFBURL:url];
  NSString *appID = params[@"app_id"];
  NSString *redirectURI = params[@"redirect_uri"];
  NSString *challenge = params[@"state"];
  NSString *expectedUrlPrefix = [FBSDKInternalUtility
                                 appURLWithHost:@"authorize"
                                 path:@""
                                 queryParameters:@{}
                                 error:NULL].absoluteString;

  XCTAssertEqualObjects(appID, _mockAppID);
  XCTAssertTrue([redirectURI hasPrefix:expectedUrlPrefix]);
  XCTAssert(challenge.length > 0);
}

- (void)testStartReferralOpensSFVC
{
  [self mockURLScheme];

  id partialBridgeAPIMock = OCMPartialMock([FBSDKBridgeAPI sharedInstance]);

  [_manager startReferralWithCompletionHandler:nil];
  OCMVerify([partialBridgeAPIMock openURLWithSafariViewController:OCMArg.any sender:OCMArg.any fromViewController:OCMArg.any handler:OCMArg.any]);
}

- (void)testReferralSuccess
{
  [self mockURLScheme];
  [self mockBridgeAPI];
  OCMStub([_manager validateChallenge:_mockChallenge]).andReturn(YES);

  NSString *queryString = [@"?fb_referral_codes=%5B%22abc%22%2C%22def%22%5D&state=" stringByAppendingString:_mockChallenge];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, queryString]];
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error");
    } else {
      NSArray<FBSDKReferralCode *> *referralCodes = result.referralCodes;
      NSArray<FBSDKReferralCode *> *expectedReferralCodes = @[[FBSDKReferralCode initWithString:@"abc"], [FBSDKReferralCode initWithString:@"def"]];
      XCTAssertEqualObjects(referralCodes, expectedReferralCodes);
      XCTAssertFalse(result.isCancelled);
      [expectation fulfill];
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  XCTAssertTrue([_manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralCancelWithOpenURLCompletionHandler
{
  [self mockURLScheme];
  [self mockBridgeAPI];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSError *cancelError = [[NSError alloc]initWithDomain:@"com.apple.SafariServices.Authentication" code:0 userInfo:nil];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error");
    } else {
      XCTAssertTrue(result.isCancelled);
      XCTAssertNil(result.referralCodes);
      [expectation fulfill];
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  [_manager handleOpenURLComplete:NO error:cancelError];

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralCancelWithAppDelegate
{
  [self mockURLScheme];
  [self mockBridgeAPI];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSURL *fakeURL = [NSURL URLWithString:@"https://www.facebook.com"];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error");
    } else {
      XCTAssertTrue(result.isCancelled);
      XCTAssertNil(result.referralCodes);
      [expectation fulfill];
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  [_manager handleOpenURLComplete:YES error:nil];
  XCTAssertFalse([_manager application:nil openURL:fakeURL sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithInvalidURLSchemes
{
  id FBSDKInternalUtilityMock = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [OCMStub(ClassMethod([FBSDKInternalUtilityMock validateURLSchemes])) andThrow:[NSException exceptionWithName:@"InvalidOperationException" reason:nil userInfo:nil]];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
      [expectation fulfill];
    } else {
      XCTFail(@"Should have error");
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithOpenURLCompletionHandler
{
  [self mockURLScheme];
  [self mockBridgeAPI];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSError *fakeError = [[NSError alloc]initWithDomain:FBSDKErrorDomain code:FBSDKErrorBridgeAPIInterruption userInfo:nil];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
      [expectation fulfill];
    } else {
      XCTFail(@"Should have error");
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  [_manager handleOpenURLComplete:NO error:fakeError];

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithAppDelegate
{
  [self mockURLScheme];
  [self mockBridgeAPI];
  OCMStub([_manager validateChallenge:_mockChallenge]).andReturn(YES);

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSString *invalidQueryString = @"?fb_referral_codes=%5B%22abc%2C%22def";
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, invalidQueryString]];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
      [expectation fulfill];
    } else {
      XCTFail(@"Should have error");
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  XCTAssertTrue([_manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithBadChallenge
{
  [self mockURLScheme];
  [self mockBridgeAPI];
  OCMStub([_manager validateChallenge:_mockChallenge]).andReturn(YES);

  NSString *badChallenge = @"badChallenge";
  NSString *queryString = [@"?fb_referral_codes=%5B%22abc%22%2C%22def%22%5D&state=" stringByAppendingString:badChallenge];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, queryString]];
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
      [expectation fulfill];
    } else {
      XCTFail(@"Should have error");
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  XCTAssertTrue([_manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralSuccessWithInvalidReferralCode
{
  [self mockURLScheme];
  [self mockBridgeAPI];
  OCMStub([_manager validateChallenge:_mockChallenge]).andReturn(YES);

  NSString *queryStringWithInvalidCode = [@"?fb_referral_codes=%5B%22abc%22%2C%22def?%22%5D&state=" stringByAppendingString:_mockChallenge];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, queryStringWithInvalidCode]];
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error");
    } else {
      NSArray<FBSDKReferralCode *> *referralCodes = result.referralCodes;
      NSArray<FBSDKReferralCode *> *expectedReferralCodes = @[[FBSDKReferralCode initWithString:@"abc"]];
      XCTAssertEqualObjects(referralCodes, expectedReferralCodes, @"Only valid referral codes should be returned");
      XCTAssertFalse(result.isCancelled);
      [expectation fulfill];
    }
  };

  [_manager startReferralWithCompletionHandler:completionHandler];
  XCTAssertTrue([_manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

@end
