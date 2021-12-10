/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@import FBSDKCoreKit;

#import "FBSDKShareModelTestUtility.h"
#import "FBSDKSharePhotoContent.h"
#import "FBSDKShareUtility.h"

@interface FBSDKSharePhotoContentTests : XCTestCase
@end

@implementation FBSDKSharePhotoContentTests

- (void)testProperties
{
  FBSDKSharePhotoContent *content = [FBSDKShareModelTestUtility photoContent];
  XCTAssertEqualObjects(content.contentURL, [FBSDKShareModelTestUtility contentURL]);
  XCTAssertEqualObjects(content.peopleIDs, [FBSDKShareModelTestUtility peopleIDs]);
  XCTAssertEqualObjects(content.photos, [FBSDKShareModelTestUtility photos]);
  XCTAssertEqualObjects(content.placeID, [FBSDKShareModelTestUtility placeID]);
  XCTAssertEqualObjects(content.ref, [FBSDKShareModelTestUtility ref]);
}

- (void)testCopy
{
  FBSDKSharePhotoContent *content = [FBSDKShareModelTestUtility photoContent];
  XCTAssertEqualObjects([content copy], content);
}

- (void)testCoding
{
  FBSDKSharePhotoContent *content = [FBSDKShareModelTestUtility photoContent];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  unarchiver.requiresSecureCoding = YES;
  FBSDKSharePhotoContent *unarchivedObject = [unarchiver decodeObjectOfClass:FBSDKSharePhotoContent.class
                                                                      forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testWithInvalidPhotos
{
  FBSDKSharePhotoContent *content = [FBSDKSharePhotoContent new];
  NSArray *photos = @[
    [FBSDKShareModelTestUtility photoWithImageURL],
    [FBSDKShareModelTestUtility photoImageURL],
  ];
  XCTAssertThrowsSpecificNamed([content setPhotos:photos], NSException, NSInvalidArgumentException);
}

- (void)testValidationWithValidContent
{
  FBSDKSharePhotoContent *content = [FBSDKSharePhotoContent new];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  content.peopleIDs = [FBSDKShareModelTestUtility peopleIDs];
  content.photos = @[[FBSDKShareModelTestUtility photoWithImage]];
  content.placeID = [FBSDKShareModelTestUtility placeID];
  content.ref = [FBSDKShareModelTestUtility ref];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilPhotos
{
  FBSDKSharePhotoContent *content = [FBSDKSharePhotoContent new];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"photos");
}

- (void)testValidationWithEmptyPhotos
{
  FBSDKSharePhotoContent *content = [FBSDKSharePhotoContent new];
  content.photos = @[];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"photos");
}

@end
