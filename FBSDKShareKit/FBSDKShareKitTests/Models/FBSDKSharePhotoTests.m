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

#import "FBSDKShareConstants.h"
#import "FBSDKShareModelTestUtility.h"
#import "FBSDKSharePhoto.h"

@interface FBSDKSharePhotoTests : XCTestCase
@end

@implementation FBSDKSharePhotoTests

- (void)testImageProperties
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImage];
  XCTAssertEqualObjects(photo.image, [FBSDKShareModelTestUtility photoImage]);
  XCTAssertNil(photo.imageURL);
  XCTAssertEqual(photo.userGenerated, [FBSDKShareModelTestUtility photoUserGenerated]);
}

- (void)testImageURLProperties
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImageURL];
  XCTAssertNil(photo.image);
  XCTAssertEqualObjects(photo.imageURL, [FBSDKShareModelTestUtility photoImageURL]);
  XCTAssertEqual(photo.userGenerated, [FBSDKShareModelTestUtility photoUserGenerated]);
}

- (void)testImageCopy
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImage];
  XCTAssertEqualObjects([photo copy], photo);
}

- (void)testImageURLCopy
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImageURL];
  XCTAssertEqualObjects([photo copy], photo);
}

- (void)testInequality
{
  FBSDKSharePhoto *photo1 = [FBSDKShareModelTestUtility photoWithImage];
  FBSDKSharePhoto *photo2 = [FBSDKShareModelTestUtility photoWithImageURL];
  XCTAssertNotEqual([photo1 hash], [photo2 hash]);
  XCTAssertNotEqualObjects(photo1, photo2);
  FBSDKSharePhoto *photo3 = [photo2 copy];
  XCTAssertEqual([photo2 hash], [photo3 hash]);
  XCTAssertEqualObjects(photo2, photo3);
  photo3.userGenerated = !photo2.userGenerated;
  XCTAssertNotEqual([photo2 hash], [photo3 hash]);
  XCTAssertNotEqualObjects(photo2, photo3);
}

- (void)testCoding
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImageURL];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:photo];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_11_0
  FBSDKSharePhoto *unarchivedPhoto = [NSKeyedUnarchiver unarchivedObjectOfClass:FBSDKSharePhoto.class fromData:data error:nil];
#else
  FBSDKSharePhoto *unarchivedPhoto = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#endif
  XCTAssertEqualObjects(unarchivedPhoto, photo);
}

- (void)testWithInvalidPhotos
{
  FBSDKSharePhotoContent *content = [FBSDKSharePhotoContent new];
  NSArray *photos = @[
    [FBSDKShareModelTestUtility photoWithImageURL],
    [FBSDKShareModelTestUtility photoWithImage],
    @"my photo",
  ];
  XCTAssertThrowsSpecificNamed([content setPhotos:photos], NSException, NSInvalidArgumentException);
}

@end
