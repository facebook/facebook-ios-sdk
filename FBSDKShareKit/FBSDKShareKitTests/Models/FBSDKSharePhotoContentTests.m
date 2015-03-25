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

#import <FBSDKShareKit/FBSDKSharePhotoContent.h>

#import <XCTest/XCTest.h>

#import "FBSDKShareModelTestUtility.h"
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
  [unarchiver setRequiresSecureCoding:YES];
  FBSDKSharePhotoContent *unarchivedObject = [unarchiver decodeObjectOfClass:[FBSDKSharePhotoContent class]
                                                                      forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testWithInvalidPhotos
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  NSArray *photos = @[
                      [FBSDKShareModelTestUtility photoWithImageURL],
                      [FBSDKShareModelTestUtility photoImageURL],
                      ];
  XCTAssertThrowsSpecificNamed([content setPhotos:photos], NSException, NSInvalidArgumentException);
}

- (void)testValidationWithValidContent
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  content.peopleIDs = [FBSDKShareModelTestUtility peopleIDs];
  content.photos = @[[FBSDKShareModelTestUtility photoWithImage]];
  content.placeID = [FBSDKShareModelTestUtility placeID];
  content.ref = [FBSDKShareModelTestUtility ref];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilPhotos
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"photos");
}

- (void)testValidationWithEmptyPhotos
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  content.photos = @[];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"photos");
}

@end
