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
#import "FBSDKShareUtility.h"
#import "FBSDKShareVideoContent.h"

@interface FBSDKShareVideoContentTests : XCTestCase
@end

@implementation FBSDKShareVideoContentTests

- (void)testProperties
{
  FBSDKShareVideoContent *content = [FBSDKShareModelTestUtility videoContentWithPreviewPhoto];
  XCTAssertEqualObjects(content.contentURL, [FBSDKShareModelTestUtility contentURL]);
  XCTAssertEqualObjects(content.peopleIDs, [FBSDKShareModelTestUtility peopleIDs]);
  XCTAssertEqualObjects(content.placeID, [FBSDKShareModelTestUtility placeID]);
  XCTAssertEqualObjects(content.ref, [FBSDKShareModelTestUtility ref]);
  XCTAssertEqualObjects(content.video, [FBSDKShareModelTestUtility videoWithPreviewPhoto]);
  XCTAssertEqualObjects(content.video.previewPhoto, [FBSDKShareModelTestUtility videoWithPreviewPhoto].previewPhoto);
}

- (void)testCopy
{
  FBSDKShareVideoContent *content = [FBSDKShareModelTestUtility videoContentWithPreviewPhoto];
  XCTAssertEqualObjects([content copy], content);
}

- (void)testCoding
{
  FBSDKShareVideoContent *content = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  unarchiver.requiresSecureCoding = YES;
  FBSDKShareVideoContent *unarchivedObject = [unarchiver decodeObjectOfClass:FBSDKShareVideoContent.class
                                                                      forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testValidationWithValidContent
{
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  content.peopleIDs = [FBSDKShareModelTestUtility peopleIDs];
  content.placeID = [FBSDKShareModelTestUtility placeID];
  content.ref = [FBSDKShareModelTestUtility ref];
  content.video = [FBSDKShareModelTestUtility videoWithPreviewPhoto];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilVideo
{
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"video");
}

- (void)testValidationWithNilVideoURL
{
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.video = [FBSDKShareVideo new];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(
    error.userInfo[FBSDKErrorArgumentNameKey],
    @"video",
    @"Attempting to validate video share content with a missing url should return a general video error"
  );
}

- (void)testValidationWithInvalidVideoURL
{
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.video = [FBSDKShareVideo new];
  content.video.videoURL = [NSURL new];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(
    error.userInfo[FBSDKErrorArgumentNameKey],
    @"videoURL",
    @"Attempting to validate video share content with an empty url should return a video url specific error"
  );
}

- (void)testValidationWithNonVideoURL
{
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.video = [FBSDKShareVideo new];
  content.video.videoURL = [FBSDKShareModelTestUtility photoImageURL];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(
    error.userInfo[FBSDKErrorArgumentNameKey],
    @"videoURL",
    @"Attempting to validate video share content with a non-video url should return a video url specific error"
  );
}

- (void)testValidationWithNetworkVideoURL
{
  FBSDKShareVideo *video = [FBSDKShareVideo videoWithVideoURL:[FBSDKShareModelTestUtility videoURL]];
  XCTAssertNotNil(video);
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.video = video;
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithValidFileVideoURLWhenBridgeOptionIsDefault
{
  NSURL *videoURL = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"video.mp4"];
  FBSDKShareVideo *video = [FBSDKShareVideo videoWithVideoURL:videoURL];
  XCTAssertNotNil(video);
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.video = video;
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(
    error.userInfo[FBSDKErrorArgumentNameKey],
    @"videoURL",
    @"Attempting to validate video share content with a valid file url should return a video url specific error when there is no specified bridge option to handle video data"
  );
}

- (void)testValidationWithValidFileVideoURLWhenBridgeOptionIsVideoData
{
  NSURL *videoURL = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"video.mp4"];
  FBSDKShareVideo *video = [FBSDKShareVideo videoWithVideoURL:videoURL];
  XCTAssertNotNil(video);
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.video = video;
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsVideoData error:&error]);
  XCTAssertNil(error);
}

@end
