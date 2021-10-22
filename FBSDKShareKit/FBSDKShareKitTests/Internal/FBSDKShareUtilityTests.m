/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#else
@import FBSDKCoreKit;
#endif

#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareUtility.h"

@interface FBSDKShareUtilityTests : XCTestCase
@end

@implementation FBSDKShareUtilityTests

- (void)testShareLinkContentValidationWithNilValues
{
  FBSDKShareLinkContent *content = [FBSDKShareLinkContent new];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testShareLinkContentValidationWithValidValues
{
  FBSDKShareLinkContent *content = [FBSDKShareLinkContent new];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  content.peopleIDs = [FBSDKShareModelTestUtility peopleIDs];
  content.placeID = [FBSDKShareModelTestUtility placeID];
  content.ref = [FBSDKShareModelTestUtility ref];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testShareLinkContentParameters
{
  FBSDKShareLinkContent *content = [FBSDKShareLinkContent new];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  XCTAssertNotNil(content.shareUUID);
  NSDictionary<NSString *, id> *parameters = [FBSDKShareUtility parametersForShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault shouldFailOnDataError:YES];
  XCTAssertEqualObjects(content.contentURL, parameters[@"messenger_link"], @"Incorrect messenger_link param.");
}

@end
