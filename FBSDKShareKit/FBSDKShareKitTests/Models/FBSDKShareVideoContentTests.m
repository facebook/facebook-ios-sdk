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

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKShareKit/FBSDKShareVideoContent.h>

#import <XCTest/XCTest.h>

#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareUtility.h"

@interface FBSDKShareVideoContentTests : XCTestCase
@end

@implementation FBSDKShareVideoContentTests

- (void)testProperties
{
  FBSDKShareVideoContent *content = [FBSDKShareModelTestUtility videoContentWithPreviewPhoto];
  XCTAssertEqualObjects(content.contentURL, [FBSDKShareModelTestUtility contentURL]);
  XCTAssertEqualObjects(content.peopleIDs, [FBSDKShareModelTestUtility peopleIDs]);
  XCTAssertEqualObjects(content.placeID, [FBSDKShareModelTestUtility placeID]);
  XCTAssertEqualObjects(content.previewPhoto, [FBSDKShareModelTestUtility photoWithImage]);
  XCTAssertEqualObjects(content.ref, [FBSDKShareModelTestUtility ref]);
  XCTAssertEqualObjects(content.video, [FBSDKShareModelTestUtility video]);
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
  [unarchiver setRequiresSecureCoding:YES];
  FBSDKShareVideoContent *unarchivedObject = [unarchiver decodeObjectOfClass:[FBSDKShareVideoContent class]
                                                                      forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testValidationWithValidContent
{
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  content.peopleIDs = [FBSDKShareModelTestUtility peopleIDs];
  content.placeID = [FBSDKShareModelTestUtility placeID];
  content.previewPhoto = [FBSDKShareModelTestUtility photoWithImage];
  content.ref = [FBSDKShareModelTestUtility ref];
  content.video = [FBSDKShareModelTestUtility video];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilVideo
{
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"video");
}

- (void)testValidationWithNilVideoURL
{
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  content.video = [[FBSDKShareVideo alloc] init];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"videoURL");
}

- (void)testValidationWithNetworkVideoURL
{
  FBSDKShareVideo *video = [FBSDKShareVideo videoWithVideoURL:[FBSDKShareModelTestUtility photoImageURL]];
  XCTAssertNotNil(video);
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  content.video = video;
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithValidFileVideoURL
{
  NSURL *videoURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"video.mp4"];
  FBSDKShareVideo *video = [FBSDKShareVideo videoWithVideoURL:videoURL];
  XCTAssertNotNil(video);
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  content.video = video;
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNil(error);
}

@end
