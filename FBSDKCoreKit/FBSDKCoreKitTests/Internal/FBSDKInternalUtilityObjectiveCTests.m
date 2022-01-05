/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKInternalUtility+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKInternalUtilityObjectiveCTests : XCTestCase

@property (nullable, nonatomic) FBSDKInternalUtility *internalUtility;

@end

@implementation FBSDKInternalUtilityObjectiveCTests

- (void)setUp
{
  [super setUp];

  self.internalUtility = [FBSDKInternalUtility new];
  [self.internalUtility configureWithInfoDictionaryProvider:[TestBundle new]
                                              loggerFactory:[TestLoggerFactory new]
                                                   settings:[TestSettings new]
                                               errorFactory:[TestErrorFactory new]];
}

- (void)tearDown
{
  self.internalUtility = nil;

  [super tearDown];
}

- (void)testCreatingUrlWithInvalidQueryString
{
  NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  [self.internalUtility URLWithScheme:FBSDKURLSchemeHTTPS
                                 host:@"example"
                                 path:@"/foo"
                      queryParameters:@{@"a date" : (NSString *) NSDate.date}
                                error:&error];

  TestSDKError *testError = (TestSDKError *)error;
  XCTAssertEqual(
    testError.type,
    TestSDKErrorTypeUnknown,
    @"Creating a url with an error reference should repopulate the error message correctly"
  );
  XCTAssertEqualObjects(
    testError.message,
    @"Unknown error building URL.",
    @"Creating a url with an error reference should repopulate the error with the appropriate type"
  );
}

@end

NS_ASSUME_NONNULL_END
