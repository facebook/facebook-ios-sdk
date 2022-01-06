/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import TestTools;

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <TestTools/TestTools.h>

#import "FBSDKInternalUtility+Testing.h"
#import "FBSDKLoginKitTests-Swift.h"
#import "FBSDKLoginUtility.h"
#import "FBSDKReferralManager+Internal.h"
#import "FBSDKReferralManager+Testing.h"
#import "FBSDKReferralManagerResult.h"

static NSString *const _mockAppID = @"mockAppID";
static NSString *const _mockChallenge = @"mockChallenge";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface FBSDKReferralManagerTests : XCTestCase

@property (nonatomic) FBSDKReferralManager *manager;
@property (nonatomic) TestBridgeAPIRequestOpener *bridgeAPIRequestOpener;
@property (nonatomic) TestInternalUtility *internalUtility;
@property (nonatomic) TestSettings *settings;
@property (nonatomic) TestErrorFactory *errorFactory;

@end

@implementation FBSDKReferralManagerTests

- (void)setUp
{
  [super setUp];

  [FBSDKReferralManager resetClassDependencies];

  self.bridgeAPIRequestOpener = [TestBridgeAPIRequestOpener new];
  self.internalUtility = [TestInternalUtility new];
  self.settings = [TestSettings new];
  self.errorFactory = [TestErrorFactory new];
  self.settings.appID = _mockAppID;
  [self configureClassDependencies];

  self.manager = [FBSDKReferralManager new];
}

- (void)tearDown
{
  self.bridgeAPIRequestOpener = nil;
  self.internalUtility = nil;
  self.settings = nil;
  self.errorFactory = nil;
  self.manager = nil;

  [FBSDKReferralManager resetClassDependencies];

  [super tearDown];
}

- (void)configureClassDependencies
{
  [FBSDKReferralManager configureWithBridgeAPIRequestOpener:self.bridgeAPIRequestOpener
                                            internalUtility:self.internalUtility
                                                   settings:self.settings
                                               errorFactory:self.errorFactory];
}

- (void)testMissingClassDependencies
{
  [FBSDKReferralManager resetClassDependencies];

  XCTAssertNil(
    FBSDKReferralManager.bridgeAPIRequestOpener,
    "ReferralManager should not have a bridge API request opener by default"
  );
  XCTAssertNil(
    FBSDKReferralManager.internalUtility,
    "ReferralManager should not have an internal utility by default"
  );
  XCTAssertNil(
    FBSDKReferralManager.settings,
    "ReferralManager should not have settings by default"
  );
  XCTAssertNil(
    FBSDKReferralManager.errorFactory,
    "ReferralManager should not have an error factory by default"
  );
}

- (void)testDefaultClassDependenciesWithNullaryInitializer
{
  [FBSDKReferralManager resetClassDependencies];

  self.manager = [FBSDKReferralManager new];

  XCTAssertEqualObjects(
    FBSDKReferralManager.bridgeAPIRequestOpener,
    FBSDKBridgeAPI.sharedInstance,
    "ReferralManager should be configured with the shared bridge API"
  );
  XCTAssertEqualObjects(
    FBSDKReferralManager.internalUtility,
    FBSDKInternalUtility.sharedUtility,
    "ReferralManager should be configured with the shared internal utility"
  );
  XCTAssertEqualObjects(
    FBSDKReferralManager.settings,
    FBSDKSettings.sharedSettings,
    "ReferralManager should be configured with the shared settings"
  );
  XCTAssertTrue(
    [(NSObject *)FBSDKReferralManager.errorFactory isKindOfClass:FBSDKErrorFactory.class],
    "ReferralManager should be configured with an error factory"
  );
}

- (void)testDefaultClassDependenciesWithUnaryInitializer
{
  [FBSDKReferralManager resetClassDependencies];

  self.manager = [[FBSDKReferralManager alloc] initWithViewController:[UIViewController new]];

  XCTAssertEqualObjects(
    FBSDKReferralManager.bridgeAPIRequestOpener,
    FBSDKBridgeAPI.sharedInstance,
    "ReferralManager should be configured with the shared bridge API"
  );
  XCTAssertEqualObjects(
    FBSDKReferralManager.internalUtility,
    FBSDKInternalUtility.sharedUtility,
    "ReferralManager should be configured with the shared internal utility"
  );
  XCTAssertEqualObjects(
    FBSDKReferralManager.settings,
    FBSDKSettings.sharedSettings,
    "ReferralManager should be configured with the shared settings"
  );
  XCTAssertTrue(
    [(NSObject *)FBSDKReferralManager.errorFactory isKindOfClass:FBSDKErrorFactory.class],
    "ReferralManager should be configured with an error factory"
  );
}

- (void)testClassDependencies
{
  [FBSDKReferralManager resetClassDependencies];
  [self configureClassDependencies];

  XCTAssertEqualObjects(
    FBSDKReferralManager.bridgeAPIRequestOpener,
    self.bridgeAPIRequestOpener,
    "ReferralManager should be configured with the bridge API request opener"
  );
  XCTAssertEqualObjects(
    FBSDKReferralManager.internalUtility,
    self.internalUtility,
    "ReferralManager should be configured with the internal utility"
  );
  XCTAssertEqualObjects(
    FBSDKReferralManager.settings,
    self.settings,
    "ReferralManager should be configured with the settings"
  );
  XCTAssertEqualObjects(
    FBSDKReferralManager.errorFactory,
    self.errorFactory,
    "ReferralManager should be configured with the error factory"
  );
}

- (void)testReferralURL
{
  NSURL *redirectURL = [NSURL URLWithString:@"sample://redirect-url"];
  self.internalUtility.stubbedAppURL = redirectURL;

  NSURL *facebookURL = [NSURL URLWithString:@"sample://facebook-url"];
  self.internalUtility.stubbedFacebookURL = facebookURL;

  NSURL *url = [self.manager referralURL];

  XCTAssertEqualObjects(
    self.internalUtility.capturedAppURLHost,
    @"authorize",
    @"The internal utility should be sent the correct app URL host"
  );
  XCTAssertEqualObjects(
    self.internalUtility.capturedAppURLPath,
    @"",
    @"The internal utility should be sent the correct app URL path"
  );
  XCTAssertEqualObjects(
    self.internalUtility.capturedAppURLQueryParameters,
    @{},
    @"The internal utility should be sent the correct app URL query parameters"
  );

  XCTAssertEqualObjects(
    self.internalUtility.capturedFacebookURLHostPrefix,
    @"m.",
    @"The internal utility should be sent the correct Facebook URL host prefix"
  );
  XCTAssertEqualObjects(
    self.internalUtility.capturedFacebookURLPath,
    @"/dialog/share_referral",
    @"The internal utility should be sent the correct Facebook URL path"
  );

  XCTAssertEqualObjects(
    self.internalUtility.capturedFacebookURLQueryParameters[@"app_id"],
    _mockAppID,
    @"The internal utility should be sent the correct Facebook URL query parameters"
  );
  XCTAssertEqualObjects(
    self.internalUtility.capturedFacebookURLQueryParameters[@"redirect_uri"],
    redirectURL.absoluteString,
    @"The internal utility should be sent the correct Facebook URL query parameters"
  );
  XCTAssertTrue(
    self.internalUtility.capturedFacebookURLQueryParameters[@"state"].length > 0,
    @"The internal utility should be sent the correct Facebook URL query parameters"
  );

  XCTAssertEqualObjects(
    url,
    facebookURL,
    @"The referral URL should be the one produced by the internal utility"
  );
}

- (void)testStartReferralOpensSFVC
{
  // Ensure a referral URL is produced
  self.internalUtility.stubbedAppURL = [NSURL URLWithString:@"sample://redirect-url"];
  self.internalUtility.stubbedFacebookURL = [NSURL URLWithString:@"sample://facebook-url"];

  [self.manager startReferralWithCompletionHandler:nil];

  XCTAssertEqual(
    self.bridgeAPIRequestOpener.openURLWithSFVCCount,
    1,
    "openURLWithSafariViewController should be called"
  );
}

- (void)testReferralSuccess
{
  // Ensure a referral URL is produced
  self.internalUtility.stubbedAppURL = [NSURL URLWithString:@"sample://redirect-url"];
  self.internalUtility.stubbedFacebookURL = [NSURL URLWithString:@"sample://facebook-url"];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error");
    } else {
      NSArray<FBSDKReferralCode *> *referralCodes = result.referralCodes;
      NSArray<FBSDKReferralCode *> *expectedReferralCodes = @[[FBSDKReferralCode initWithString:@"abc"], [FBSDKReferralCode initWithString:@"def"]];
      XCTAssertEqualObjects(referralCodes, expectedReferralCodes);
      XCTAssertFalse(result.isCancelled);
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];

  // Set up challenge and referral codes
  self.manager.expectedChallenge = _mockChallenge;
  self.internalUtility.stubbedFBURLParameters = @{
    @"state" : _mockChallenge,
    @"fb_referral_codes" : @"[\"abc\",\"def\"]"
  };

  NSString *queryString = [@"?fb_referral_codes=%5B%22abc%22%2C%22def%22%5D&state=" stringByAppendingString:self.manager.expectedChallenge];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, queryString]];

  XCTAssertTrue([self.manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralCancelWithOpenURLCompletionHandler
{
  // Ensure a referral URL is produced
  self.internalUtility.stubbedAppURL = [NSURL URLWithString:@"sample://redirect-url"];
  self.internalUtility.stubbedFacebookURL = [NSURL URLWithString:@"sample://facebook-url"];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSError *cancelError = [[NSError alloc] initWithDomain:@"com.apple.SafariServices.Authentication" code:0 userInfo:nil];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error");
    } else {
      XCTAssertTrue(result.isCancelled);
      XCTAssertNil(result.referralCodes);
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];
  [self.manager handleOpenURLComplete:NO error:cancelError];

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralCancelWithAppDelegate
{
  // Ensure a referral URL is produced
  self.internalUtility.stubbedAppURL = [NSURL URLWithString:@"sample://redirect-url"];
  self.internalUtility.stubbedFacebookURL = [NSURL URLWithString:@"sample://facebook-url"];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSURL *fakeURL = [NSURL URLWithString:@"https://www.facebook.com"];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error");
    } else {
      XCTAssertTrue(result.isCancelled);
      XCTAssertNil(result.referralCodes);
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];
  [self.manager handleOpenURLComplete:YES error:nil];
  XCTAssertFalse([self.manager application:nil openURL:fakeURL sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithInvalidURLSchemes
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
    } else {
      XCTFail(@"Should have error");
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithOpenURLCompletionHandler
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSError *fakeError = [[NSError alloc]initWithDomain:FBSDKErrorDomain code:FBSDKErrorBridgeAPIInterruption userInfo:nil];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
    } else {
      XCTFail(@"Should have error");
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];
  [self.manager handleOpenURLComplete:NO error:fakeError];

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithAppDelegate
{
  self.manager.expectedChallenge = @"mockChallenge";

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSString *invalidQueryString = @"?fb_referral_codes=%5B%22abc%2C%22def";
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, invalidQueryString]];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
    } else {
      XCTFail(@"Should have error");
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];
  XCTAssertTrue([self.manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralErrorWithBadChallenge
{
  self.manager.expectedChallenge = @"mockChallenge";;

  NSString *badChallenge = @"badChallenge";
  NSString *queryString = [@"?fb_referral_codes=%5B%22abc%22%2C%22def%22%5D&state=" stringByAppendingString:badChallenge];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, queryString]];
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTAssertNil(result);
    } else {
      XCTFail(@"Should have error");
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];
  XCTAssertTrue([self.manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testReferralSuccessWithInvalidReferralCode
{
  // Ensure a referral URL is produced
  self.internalUtility.stubbedAppURL = [NSURL URLWithString:@"sample://redirect-url"];
  self.internalUtility.stubbedFacebookURL = [NSURL URLWithString:@"sample://facebook-url"];

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKReferralManagerResultBlock completionHandler = ^(FBSDKReferralManagerResult *result, NSError *referralError) {
    if (referralError) {
      XCTFail(@"Should not have error: %@", referralError);
    } else {
      NSArray<FBSDKReferralCode *> *referralCodes = result.referralCodes;
      NSArray<FBSDKReferralCode *> *expectedReferralCodes = @[[FBSDKReferralCode initWithString:@"abc"]];
      XCTAssertEqualObjects(referralCodes, expectedReferralCodes, @"Only valid referral codes should be returned");
      XCTAssertFalse(result.isCancelled);
    }

    [expectation fulfill];
  };

  [self.manager startReferralWithCompletionHandler:completionHandler];

  // Set up challenge and referral codes
  self.manager.expectedChallenge = _mockChallenge;
  self.internalUtility.stubbedFBURLParameters = @{
    @"state" : _mockChallenge,
    @"fb_referral_codes" : @"[\"abc\"]"
  };

  NSString *queryStringWithInvalidCode = [@"?fb_referral_codes=%5B%22abc%22%2C%22def?%22%5D&state=" stringByAppendingString:self.manager.expectedChallenge];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@", _mockAppID, queryStringWithInvalidCode]];

  XCTAssertTrue([self.manager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

@end

#pragma clang diagnostic pop
