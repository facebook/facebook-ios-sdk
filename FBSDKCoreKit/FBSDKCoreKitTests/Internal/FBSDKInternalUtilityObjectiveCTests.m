/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKInternalUtilityObjectiveCTests : XCTestCase

@property (nullable, nonatomic) FBSDKInternalUtility *internalUtility;

@end

@implementation FBSDKInternalUtilityObjectiveCTests

- (void)setUp
{
  [super setUp];

  self.internalUtility = [FBSDKInternalUtility new];
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

  XCTAssertEqualObjects(
    error.domain,
    @"com.facebook.sdk.core",
    "Creating a url with an error reference should repopulate the error domain correctly"
  );
  XCTAssertEqual(
    error.code,
    3,
    "Creating a url with an error reference should repopulate the error code correctly"
  );
  XCTAssertEqualObjects(
    [error.userInfo objectForKey:FBSDKErrorDeveloperMessageKey],
    @"Unknown error building URL.",
    "Creating a url with an error reference should repopulate the error message correctly"
  );
}

@end

NS_ASSUME_NONNULL_END
