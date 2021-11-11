/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

@import FBSDKCoreKit;

#import <XCTest/XCTest.h>

#import "FBSDKShareLinkContent.h"
#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareUtility.h"

@interface FBSDKShareLinkContentTests : XCTestCase
@end

@implementation FBSDKShareLinkContentTests

- (void)testProperties
{
  FBSDKShareLinkContent *content = [FBSDKShareModelTestUtility linkContent];
  XCTAssertEqualObjects(content.contentURL, [FBSDKShareModelTestUtility contentURL]);
  XCTAssertEqualObjects(content.hashtag, [FBSDKShareModelTestUtility hashtag]);
  XCTAssertEqualObjects(content.peopleIDs, [FBSDKShareModelTestUtility peopleIDs]);
  XCTAssertEqualObjects(content.placeID, [FBSDKShareModelTestUtility placeID]);
  XCTAssertEqualObjects(content.ref, [FBSDKShareModelTestUtility ref]);
  XCTAssertEqualObjects(content.quote, [FBSDKShareModelTestUtility quote]);
}

- (void)testCopy
{
  FBSDKShareLinkContent *content = [FBSDKShareModelTestUtility linkContent];
  XCTAssertEqualObjects([content copy], content);
}

- (void)testCoding
{
  FBSDKShareLinkContent *content = [FBSDKShareModelTestUtility linkContent];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  unarchiver.requiresSecureCoding = YES;
  FBSDKShareLinkContent *unarchivedObject = [unarchiver decodeObjectOfClass:FBSDKShareLinkContent.class
                                                                     forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testWithInvalidPeopleIDs
{
  FBSDKShareLinkContent *content = [FBSDKShareLinkContent new];
  NSArray *array = @[
    @"one",
    @2,
    @"three",
  ];
  XCTAssertThrowsSpecificNamed([content setPeopleIDs:array], NSException, NSInvalidArgumentException);
}

- (void)testValidationWithValidContent
{
  NSError *error;
  XCTAssertTrue(
    [FBSDKShareUtility validateShareContent:[FBSDKShareModelTestUtility linkContent]
                              bridgeOptions:FBSDKShareBridgeOptionsDefault
                                      error:&error]
  );
  XCTAssertNil(error);
}

@end
